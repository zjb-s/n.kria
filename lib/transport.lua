Transport = {}

function Transport:play_pause()
	params:delta('playing', 1)
	post((params:get('playing') == 1) and 'play' or 'pause')
end

function Transport:reset_all()
	for t=1,NUM_TRACKS do
		self:reset_track(t)
	end
	pulse_indicator = 1
	params:set('pattern_quant_pos',1)
	params:set('ms_duration_pos',1)
	swing_this_step = false
	post('reset all')
end

function Transport:reset_track(t)
	for k,v in ipairs(combined_page_list) do
		if v == 'scale' or v == 'patterns' then break end
		self:reset_page(t,v)
	end
	post('reset track '..t)
end

function Transport:reset_page(t,p)
	data:set_page_val(t,p,'pos',data:get_page_val(t,p,'loop_last'))
	data:set_page_val(t,p,'counter',data:get_page_val(t,p,'divisor'))
end

function Transport:advance_all()
	global_clock_counter = global_clock_counter + 1
	if global_clock_counter > params:get('global_clock_div') then
		global_clock_counter = 1
		pulse_indicator = pulse_indicator + 1
		if pulse_indicator > 16 then pulse_indicator = 1 end

		self:advance_pattern_page()
		
		for t=1,NUM_TRACKS do 
			self:advance_track(t) 
		end
	end
end

function Transport:advance_pattern_page()
	params:delta('pattern_quant_pos',1)

	if params:get('pattern_quant_pos') <= params:get('pattern_quant') then return end
	
	params:set('pattern_quant_pos',1)
	if params:get('cued_pattern') ~= 0 then
		params:set('active_pattern',params:get('cued_pattern'))
		params:set('cued_pattern',0)
		post('pattern '..ap()..' active')
	end

	if params:get('ms_active') == 0 then return end

	params:delta('ms_duration_pos',1)
	if params:get('ms_duration_pos') > params:get('ms_duration_'..params:get('ms_pos')) then
		params:set('ms_duration_pos',1)
		params:delta('ms_pos',1)
		if params:get('ms_pos') > params:get('ms_last') or params:get('ms_pos') < params:get('ms_first') then
			params:set('ms_pos',1)
		end
	end

	params:set('active_pattern',params:get('ms_pattern_'..params:get('ms_pos')))
end

function Transport:advance_track(t)
	local pages_to_advance = (data:get_track_val(t,'trigger_clock') == 1) and {'trig','retrig'} or pages_with_steps

	for k,v in pairs(pages_to_advance) do
		data:delta_page_val(t,v,'counter',1)
		if data:get_page_val(t,v,'counter') > data:get_page_val(t,v,'divisor') then
			data:set_page_val(t,v,'counter',1)
			self:advance_page(t,v)
			if data:get_track_val(t,'mute') == 0 
			and math.random(0,99) < prob_map[data:get_unique(t,'trig_prob',data:get_page_val(t,'trig','pos'))]
			then
				value_buffer[t][v] = data:get_step_val(t,v,data:get_page_val(t,v,'pos'))
									 --data:get_step_val(t,v,data:get_page_val(t,v,'pos'))
				if v == 'trig' and current_val(t,'trig') == 1 then
					clock.run(note_clock,t)
				end
			end
		end
	end
end

function Transport:advance_page(t,p) -- track,page
	local old_pos = data:get_page_val(t,p,'pos')
	local first = data:get_page_val(t,p,'loop_first')
	local last = data:get_page_val(t,p,'loop_last')
	local mode = play_modes[data:get_track_val(t,'play_mode')]
	local new_pos;
	local resetting = false

	if mode == 'forward' then
		new_pos = old_pos + 1
		if out_of_bounds(t,p,new_pos) then
			new_pos = first
			resetting = true
		end
	elseif mode == 'reverse' then
		new_pos = old_pos - 1
		if out_of_bounds(t,p,new_pos) then
			new_pos = last
			resetting = true
		end
	elseif mode == 'triangle' then
		local delta = data:get_page_val(t,p,'pipo_dir') == 1 and 1 or -1
		new_pos = old_pos + delta
		if out_of_bounds(t,p,new_pos) then 
			if new_pos > last then
				new_pos = util.clamp(last-1,first,last)
				data:set_page_val(t,p,'pipo_dir',0)
			elseif new_pos < first then
				new_pos = util.clamp(first+1,first,last)
				data:set_page_val(t,p,'pipo_dir',1)
			end
			resetting = true
		end
	elseif mode == 'drunk' then 
		local delta
		if new_pos == first then delta = 1
		elseif new_pos == last then delta = -1
		else delta = math.random() > 0.5 and 1 or -1
		end
		new_pos = old_pos + delta
		if new_pos > last then 
			new_pos = last
		elseif new_pos < first then
			new_pos = first
		end
		-- ^ have to do it this way vs out_of_bounds() because we want to get to the closest boundary, not necessarily first or last step in loop.

	elseif mode == 'random' then 
		new_pos = util.round(math.random(first,last))
	end

	if resetting and data:get_page_val(t,p,'cued_divisor') ~= 0 then
		data:set_page_val(t,p,'divisor',data:get_page_val(t,p,'cued_divisor'))
		data:set_page_val(t,p,'cued_divisor',0)
	end


	data:set_page_val(t,p,'pos',new_pos)
end 


return Transport
