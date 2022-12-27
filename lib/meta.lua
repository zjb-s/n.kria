Meta = {}

function Meta:reset()
	for t=1,NUM_TRACKS do
		for k,v in ipairs(combined_page_list) do
			if v == 'scale' or v == 'patterns' then break end
			data:set_page_val(t,v,'pos',data:get_page_val(t,v,'loop_last'))
			data:set_page_val(t,v,'counter',data:get_page_val(t,v,'divisor'))
		end
	end
	pulse_indicator = 1
	post('reset')
end

function Meta:note_out(t)
	local s = make_scale()
	local n = s[current_val(t,'note') + (current_val(t,'transpose')-1)]
	-- print('note is',n)
	n = n + 12*current_val(t,'octave')
	n = n + params:get('root_note')
	data:set_track_val(t,'last_note',n)

	local gate_len = current_val(t,'gate') -- this will give you a weird range, feel free to use it however you want
	-- local gate_multiplier = params:get('data_gate_shift_t'..t) 
	local gate_multiplier = data:get_track_val(t,'gate_shift')
	local slide_amt =  util.linlin(1,7,1,120,current_val(t,'slide')) -- to match stock kria times
	local duration = util.clamp(gate_len-1, 0, 4)/16
	if gate_len == 1 or gate_len == 6 then
		duration = duration + 0.02 -- this turns the longest notes into ties, and the shortest into blips, at mult of 1
	else
		duration = duration - 0.02
	end
	duration = duration * gate_multiplier
	clock.run(note_clock, t, n, duration, slide_amt)
end

function Meta:advance_all()
	global_clock_counter = global_clock_counter + 1
	if global_clock_counter > params:get('global_clock_div') then
		global_clock_counter = 1

		pulse_indicator = pulse_indicator + 1
		if pulse_indicator > 16 then pulse_indicator = 1 end

		local will_track_fire = {}
		
		for t=1,NUM_TRACKS do
			for k,v in ipairs(combined_page_list) do
				if v == 'scale' or v == 'patterns' then break end
				data:delta_page_val(t,v,'counter',1)
				if data:get_page_val(t,v,'counter') > data:get_page_val(t,v,'divisor') then
					data:set_page_val(t,v,'counter',1)
					self:advance_page(t,v)
					if v == 'trig' then will_track_fire[t] = true end
				end
			end
		end

		for t=1,4 do
			if 	will_track_fire[t]
			and data:get_track_val(t,'mute') == 0
			and	current_val(t,'trig') == 1
			and math.random(0,99) < prob_map[params:get('data_trig_prob_'..data:get_page_val(t,'trig','pos')..'_t'..at()..'_p'..ap())]
			then -- ^^ this is truly unbearable and must be stopped lol
				-- print('playing note on track '..t)
				self:note_out(t)
			end
		end
	end
end

function Meta:advance_page(t,p) -- track,page
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
		local delta = data:get_track_val(t,'pipo_dir') == 1 and 1 or -1
		new_pos = old_pos + delta
		if out_of_bounds(t,p,new_pos) then 
			--print(delta)
			new_pos = (delta == -1) and last-1 or first+1
			-- print('new pos is',new_pos,'first is',first,'last is',last)
			data:delta_track_val(t,'pipo_dir',1)
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
end -- todo there's something very wrong with triangle mode...


function Meta:toggle_subtrig(track,step,subtrig)
	params:delta('data_subtrig_'..subtrig..'_step_'..step..'_t'..track..'_p'..ap(),1)
	for i=params:get('data_subtrig_count_'..step..'_t'..track..'_p'..ap()),1,-1 do
		if params:get('data_subtrig_'..i..'_step_'..step..'_t'..track..'_p'..ap()) == 0 then
			-- print('decrementing subtrig count')
			self:delta_subtrig_count(track,step,-1)
		else
			break
		end
	end
end

function Meta:delta_subtrig_count(track,step,delta)
	self:edit_subtrig_count(track,step,params:get('data_subtrig_count_'..step..'_t'..track..'_p'..ap()) + delta)
end

function Meta:edit_subtrig_count(track,step,new_val)
	params:set('data_subtrig_count_'..step..'_t'..track..'_p'..ap(),new_val)
	for i=1,5 do
		if	params:get('data_subtrig_'..i..'_step_'..step..'_t'..track..'_p'..ap()) == 1 and i > new_val then
			params:set('data_subtrig_'..i..'_step_'..step..'_t'..track..'_p'..ap(),0)
		end
	end
	post('subtrig count s'..step..'t'..track..' '.. params:get('data_subtrig_count_'..step..'_t'..track..'_p'..ap()))
end

function Meta:edit_divisor(track,page,new_val)
	if params:get('div_cue') == 1 then
		data:set_page_val(track,page,'cued_divisor',new_val)
		post('cued: '..page..' divisor: '..new_val)
	else
		data:set_page_val(track,page,'divisor',new_val)
		post(page..' divisor: '..new_val)
	end
end

function Meta:edit_loop(track, first, last)
	local f = math.min(first,last)
	local l = math.max(first,last)
	local p = get_page_name()
	local loopsync = div_sync_modes[params:get('loop_sync')]

	if loopsync == 'none' then
		if p == 'trig' or p == 'note' and params:get('note_sync') == 1 then
			data:set_page_val(track,'note','loop_first',f)
			data:set_page_val(track,'note','loop_last',l)
			data:set_page_val(track,'trig','loop_first',f)
			data:set_page_val(track,'trig','loop_last',l)
			post('t'..track..' trig & note loops: ['..f..'-'..l..']')
		else
			data:set_page_val(track,p,'loop_first',f)
			data:set_page_val(track,p,'loop_last',l)
			post('t'..track..' '..p..' loop: ['..f..'-'..l..']')
		end
	elseif loopsync == 'track' then
		for k,v in ipairs(combined_page_list) do
			if v == 'scale' or v == 'patterns' then break end
			data:set_page_val(track,v,'loop_first',f)
			data:set_page_val(track,v,'loop_last',l)
		end
		post('t'..track..' loops: ['..f..'-'..l..']')
	elseif loopsync == 'all' then
		for t=1,NUM_TRACKS do
			for k,v in ipairs(combined_page_list) do
				if v == 'scale' or v == 'patterns' then break end
				data:set_page_val(track,v,'loop_first',f)
				data:set_page_val(track,v,'loop_last',l)
			end
		end
		post('all loops: ['..f..'-'..l..']')
	end
end

return Meta