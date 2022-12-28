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
	params:set('pattern_quant_pos',1)
	params:set('ms_duration_pos',1)
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

		params:delta('pattern_quant_pos',1)
		if params:get('pattern_quant_pos') > params:get('pattern_quant') then
			params:set('pattern_quant_pos',1)
			if params:get('cued_pattern') ~= 0 then
				params:set('active_pattern',params:get('cued_pattern'))
				params:set('cued_pattern',0)
				post('pattern '..ap()..' active')

			end
			if params:get('ms_active') == 1 then
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
		end


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
			and math.random(0,99) < prob_map[data:get_unique(t,'trig_prob',data:get_page_val(t,'trig','pos'))]
			then 
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
			new_pos = (delta == -1) and last-1 or first+1
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


function Meta:toggle_subtrig(track,step,aux)
	data:delta_unique(track,'subtrig',step,aux)
	for i=data:get_unique(track,'subtrig_count',step),1,-1 do
		if not data:get_unique(track,'subtrig',step,i) then
			self:delta_subtrig_count(track,step,-1)
		else
			break
		end
	end
end

function Meta:delta_subtrig_count(track,step,delta)
	self:edit_subtrig_count(track,step,data:get_unique(track,'subtrig_count',step)+delta)
end

function Meta:edit_subtrig_count(track,step,new_val)
	data:set_unique(track,'subtrig_count',step,new_val)
	for i=1,5 do
		if	data:get_unique(track,'subtrig',step,i) and i > new_val then
			data:set_unique(track,'subtrig',step,i,false)
		end
	end
	post('subtrig count s'..step..'t'..track..' '.. data:get_unique(track,'subtrig_count',step))
end

function Meta:edit_divisor(track,page,new_val)
	if params:get('div_cue') == 1 then
		data:set_page_val(track,page,'cued_divisor',new_val)
		post('cued: '..page..' divisor: '..division_names[new_val])
	else
		data:set_page_val(track,page,'divisor',new_val)
		post(page..' divisor: '..division_names[new_val])
	end
end

function Meta:edit_loop(track, first, last)
	local f = math.min(first,last)
	local l = math.max(first,last)
	local p = get_page_name()
	local loopsync = div_sync_modes[params:get('loop_sync')]

	if p == 'pattern' and params:get('ms_active') == 1 then
		params:set('ms_first',f)
		params:set('ms_last',l)
		post('meta-sequence loop: ['..f..'-'..l..']')
	elseif loopsync == 'none' then
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

function Meta:switch_to_pattern(p)
	post('cued pattern '..p)
	params:set('cued_pattern',p)
end

function Meta:save_pattern_into_slot(slot)
	for t=1,NUM_TRACKS do 
		self:paste_onto_track(t,self:get_track_copy(t),slot) 
		post('saved pattern to slot '..slot)
	end
end

function Meta:get_track_copy(T,p)
	local r = {}
	local t = T and T or last_touched_track
	data.pattern = p and p or ap()
	for k,v in ipairs(combined_page_list) do
		if v == 'scale' or v == 'patterns' then break end
		r[v] = {}
		r[v]['pos'] = data:get_page_val(t,v,'pos')
		r[v]['loop_first'] = data:get_page_val(t,v,'loop_first')
		r[v]['loop_last'] = data:get_page_val(t,v,'loop_last')
		r[v]['divisor'] = data:get_page_val(t,v,'divisor')
		r[v]['cued_divisor'] = data:get_page_val(t,v,'cued_divisor')
		r[v]['counter'] = data:get_page_val(t,v,'counter')
		r[v].vals = {}
		r[v].probs = {}
		if v == 'retrig' then
			r[v].subtrig_counts = {}
			r[v].subtrigs = {}
		end
		for i=1,16 do
			table.insert(r[v].vals,data:get_step_val(t,v,i))
			table.insert(r[v].probs,data:get_unique(t,v..'_prob',i))
			if v == 'retrig' then
				table.insert(r[v].subtrig_counts,data:get_unique(t,'subtrig_count',i))
				table.insert(r[v].subtrigs,{})
				for j=1,5 do
					table.insert(r[v].subtrigs[i],data:get_unique(t,'subtrig',i,j))
				end
			end
		end
	end
	data.pattern = ap()
	post('copied track '..t)
	return r
end

function Meta:paste_onto_track(t,track_table,p)
	data.pattern = p and p or ap()
	for k,v in ipairs(combined_page_list) do
		if v == 'scale' or v == 'patterns' then break end
		data:set_page_val(t,v,'pos',track_table[v].pos)
		data:set_page_val(t,v,'loop_first',track_table[v].loop_first)
		data:set_page_val(t,v,'loop_last',track_table[v].loop_last)
		data:set_page_val(t,v,'divisor',track_table[v].divisor)
		data:set_page_val(t,v,'cued_divisor',track_table[v].cued_divisor)
		data:set_page_val(t,v,'counter',track_table[v].counter)
		for i=1,16 do
			data:set_step_val(t,v,i,track_table[v].vals[i])
			data:set_unique(t,v..'_prob',i,track_table[v].probs[i])
			if v == 'retrig' then
				for j=1,5 do
					data:set_unique(t,'subtrig',i,j,track_table[v].subtrigs[j])
				end
			end
		end
	end
	post('pasted on track '..t)
	data.pattern = ap()
end

return Meta