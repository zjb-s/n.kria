Meta = {}

function Meta:reset()
	for t=1,NUM_TRACKS do
		for k,v in ipairs(combined_page_list) do
			if v == 'scale' or v == 'patterns' then break end
			params:set('pos_'..v..'_t'..t, params:get('loop_last_'..v..'_t'..t))
		end
	end
	pulse_indicator = 1
	post('reset')
end

function Meta:note_out(t)
	local s = make_scale()
	local n = s[current_val(t,'note')] + s[current_val(t,'transpose')]
	local up_one_octave = false
	if n > 7 then
		n = n - 7
		up_one_octave = true
	end
	n = n + 12*current_val(t,'octave')
	if up_one_octave then n = n + 12 end
	local gate_len = current_val(t,'gate') -- this will give you a weird range, feel free to use it however you want
	local gate_multiplier = params:get('data_gate_shift_t'..t) 
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
		
		for t=1,NUM_TRACKS do
			for k,v in ipairs(combined_page_list) do
				if v == 'scale' or v == 'patterns' then break end
				params:delta('data_t'..t..'_'..v..'_counter',1)
				if 		params:get('data_t'..t..'_'..v..'_counter')
					>	params:get('divisor_'..v..'_t'..t) 
				then
					params:set('data_t'..t..'_'..v..'_counter',1)
					self:advance_page(t,v)
					-- params:set('pos_'..v..'_t'..t,new_pos_for_track(t,v))
					if 	math.random(0,99)
					< 	prob_map[params:get('data_'..v..'_prob_'..params:get('pos_'..v..'_t'..t)..'_t'..t)]
					then
						update_val(t,v)
					end
				end
			end
		end
	end
end

function Meta:advance_page(t,p) -- track,page
	local old_pos = params:get('pos_'..p..'_t'..t)
	local first = params:get('loop_first_'..p..'_t'..t)
	local last = params:get('loop_last_'..p..'_t'..t)
	local mode = play_modes[params:get('playmode_t'..t)]
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
		local delta = params:get('pipo_dir_t'..t) == 1 and 1 or -1
		new_pos = old_pos + delta
		if out_of_bounds(t,p,new_pos) then 
			--print(delta)
			new_pos = (delta == -1) and last-1 or first+1
			print('new pos is',new_pos,'first is',first,'last is',last)
			params:delta('pipo_dir_t'..t,1)
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

	if resetting and params:get('cued_divisor_'..p..'_t'..t) ~= 0 then
		params:set('divisor_'..p..'_t'..t, params:get('cued_divisor_'..p..'_t'..t))
		params:set('cued_divisor_'..p..'_t'..t,0)
	end

	params:set('pos_'..p..'_t'..t,new_pos)
end -- todo there's something very wrong with triangle mode...


function Meta:toggle_subtrig(track,step,subtrig)
	params:delta('data_subtrig_'..subtrig..'_step_'..step..'_t'..track,1)
	for i=params:get('data_subtrig_count_'..step..'_t'..track),1,-1 do
		if params:get('data_subtrig_'..i..'_step_'..step..'_t'..track) == 0 then
			-- print('decrementing subtrig count')
			self:delta_subtrig_count(track,step,-1)
		else
			break
		end
	end
end

function Meta:delta_subtrig_count(track,step,delta)
	self:edit_subtrig_count(track,step,params:get('data_subtrig_count_'..step..'_t'..track) + delta)
end

function Meta:edit_subtrig_count(track,step,new_val)
	params:set('data_subtrig_count_'..step..'_t'..track,new_val)
	for i=1,5 do
		if	params:get('data_subtrig_'..i..'_step_'..step..'_t'..track) == 1 and i > new_val then
			params:set('data_subtrig_'..i..'_step_'..step..'_t'..track,0)
		end
	end
	post('subtrig count s'..step..'t'..track..' '.. params:get('data_subtrig_count_'..step..'_t'..track))
end

function Meta:edit_divisor(track,page,new_val)
	if params:get('div_cue') == 1 then
		params:set('cued_divisor_'..page..'_t'..track,new_val)
		post('cued: '..page..' divisor: '..new_val)
	else
		params:set('divisor_'..page..'_t'..track,new_val)
		post(page..' divisor: '..new_val)
	end
end

function Meta:edit_loop(track, first, last)
	local f = math.min(first,last)
	local l = math.max(first,last)
	local p = get_page_name()

	if params:get('loop_sync') == 1 then
		if p == 'trig' or p == 'note' and params:get('note_sync') == 1 then
			params:set('loop_first_note_t'..track,f)
			params:set('loop_last_note_t'..track,l)
			params:set('loop_first_trig_t'..track,f)
			params:set('loop_last_trig_t'..track,l)
			post('t'..track..' trig & note loops: ['..f..'-'..l..']')
		else
			params:set('loop_first_'..p..'_t'..track,f)
			params:set('loop_last_'..p..'_t'..track,l)
			post('t'..track..' '..p..' loop: ['..f..'-'..l..']')
		end
	elseif params:get('loop_sync') == 2 then
		for k,v in ipairs(combined_page_list) do
			if v == 'scale' or v == 'patterns' then break end
			params:set('loop_first_'..v..'_t'..track,f)
			params:set('loop_last_'..v..'_t'..track,l)
		end
		post('t'..track..' loops: ['..f..'-'..l..']')
	elseif params:get('loop_sync') == 3 then
		for t=1,NUM_TRACKS do
			for k,v in ipairs(combined_page_list) do
				if v == 'scale' or v == 'patterns' then break end
				params:set('loop_first_'..v..'_t'..t,f)
				params:set('loop_last_'..v..'_t'..t,l)
			end
		end
		post('all loops: ['..f..'-'..l..']')
	end
end

return Meta