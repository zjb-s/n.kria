-- matrix
local status, matrix = pcall(require, 'matrix/lib/matrix')
if not status then matrix = nil end

Transport = {}

function Transport:play_pause()
	data:delta_global_val('playing', 1)
	post((data:get_global_val('playing') == 1) and 'play' or 'pause')
end

function Transport:reset_all()
	for t=1,NUM_TRACKS do
		self:reset_track(t)
	end
	pulse_indicator = 1
	data:set_global_val('pattern_quant_pos',1)
	data:set_global_val('ms_duration_pos',1)
	swing_this_step = false
	post('reset all tracks')
end

function Transport:reset_track(t)
	for k,v in ipairs(combined_page_list) do
		if v == 'scale' or v == 'patterns' then break end
		self:reset_page(t,v)
	end
	post('reset track '..t)
end

function Transport:reset_page(t,p)
	-- print('resetting')
	data:set_page_val(t,p,'pos',data:get_page_val(t,p,'loop_last'))
	data:set_page_val(t,p,'counter',data:get_page_val(t,p,'divisor'))
end

function Transport:advance_all()
	global_clock_counter = global_clock_counter + 1
	if global_clock_counter > data:get_global_val('clock_div') then
		global_clock_counter = 1
		pulse_indicator = pulse_indicator + 1
		if pulse_indicator > 16 then pulse_indicator = 1 end

		self:advance_pattern_page()
		
		for t=1,NUM_TRACKS do 
			if data:get_track_val(t,'param_clock') == 0 then 
				self:advance_track(t) 
			end
		end
	end
end

function Transport:advance_pattern_page()
	data:delta_global_val('pattern_quant_pos',1)

	if data:get_global_val('pattern_quant_pos') <= data:get_global_val('pattern_quant') then return end
	
	data:set_global_val('pattern_quant_pos',1)
	if data:get_global_val('cued_pattern') ~= 0 then
		data:set_global_val('active_pattern',data:get_global_val('cued_pattern'))
		data:set_global_val('cued_pattern',0)
		post('pattern '..ap()..' active')
	end

	if data:get_global_val('ms_active') == 0 then return end

	data:delta_global_val('ms_duration_pos',1)
	if data:get_global_val('ms_duration_pos') > data:get_global_val('ms_duration_'..data:get_global_val('ms_pos')) then
		data:set_global_val('ms_duration_pos',1)
		data:delta_global_val('ms_pos',1)
		if data:get_global_val('ms_pos') > data:get_global_val('ms_last') or data:get_global_val('ms_pos') < data:get_global_val('ms_first') then
			data:set_global_val('ms_pos',1)
		end
	end

	data:set_global_val('active_pattern',data:get_global_val('ms_pattern_'..data:get_global_val('ms_pos')))
end

function Transport:advance_track(t)
	-- local pages_to_advance = (data:get_track_val(t,'trigger_clock') == 1) and {'trig','retrig'} or trigger_clock_pages
	local pages_to_advance;
	if data:get_track_val(t,'trigger_clock') == 1 then
		if t==1 then print('trigger clock is on') end
		pages_to_advance = trig_and_retrig_pages
	else
		if t==1 then print('trigger clock is off') end
		pages_to_advance = pages_with_steps
	end

	local note_will_fire = false
	for k,v in pairs(pages_to_advance) do
		-- print('attempting to advance page',v)
		data:delta_page_val(t,v,'counter',1)
		if data:get_page_val(t,v,'counter') > data:get_page_val(t,v,'divisor') then
			data:set_page_val(t,v,'counter',1)
			if type(data.tracks[t][v].temp_loop_first) == 'number' then
				if self:advance_page(t,v, false, true) then note_will_fire = true end
				self:advance_page(t, v, true, false)
				-- print(t, v, "fake", data:get_pos(t, v), "real", data:get_page_val(t,v,'pos'))
			else
				if self:advance_page(t,v, true, true) then note_will_fire = true end
			end
		end
	end
	if note_will_fire then clock.run(note_clock,t) end
end

function Transport:advance_page(t,p,real,playing) -- track,page
	local old_pos = real and data:get_page_val(t,p,'pos') or data:get_pos(t, p)
	local first = real and data:get_page_val(t,p,'loop_first') or data:get_loop_first(t, p)
	local last = real and data:get_page_val(t,p,'loop_last') or data:get_loop_last(t, p)
	local mode = play_modes[data:get_track_val(t,'play_mode')]
	local new_pos;
	local resetting = false
	-- if p=='note' and t==1 then print(mode) end

	if mode == 'forward' then
		new_pos = old_pos + 1
		if out_of_bounds(t,p,new_pos, real) then
			new_pos = first
			resetting = true
		end
	elseif mode == 'reverse' then
		new_pos = old_pos - 1
		if out_of_bounds(t,p,new_pos, real) then
			new_pos = last
			resetting = true
		end
	elseif mode == 'triangle' then
		local delta = data:get_page_val(t,p,'pipo_dir') == 1 and 1 or -1
		new_pos = old_pos + delta
		if out_of_bounds(t,p,new_pos, real) then 
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

	if resetting and playing and data:get_page_val(t,p,'cued_divisor') ~= 0 then
		data:set_page_val(t,p,'divisor',data:get_page_val(t,p,'cued_divisor'))
		data:set_page_val(t,p,'cued_divisor',0)
	end

	if real then
		if t==1 and p=='trig' then print('calling advance on trig page') end
		data:set_page_val(t,p,'pos',new_pos)
	else
		data.tracks[t][p].temp_pos = new_pos
	end

	if playing and math.random(0,99) < prob_map[data:get_step_val(t,p,data:get_pos(t,p), 'prob')] then
		if matrix and tab.contains(matrix_sources,p) then 
			matrix:set(p..'_t'..t, (data:get_step_val(t,p,data:get_pos(t,p))-1)/6) 
		end
		if data:get_track_val(t,'mute') == 0 then
			value_buffer[t][p] = data:get_step_val(t,p,data:get_pos(t,p))
			if p == 'trig' and current_val(t,'trig') == 1 then
				return true
			end
		end
	end
end 


return Transport
