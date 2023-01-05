--[[
WHAT GOES IN THIS FILE:
- utility, sanity and sugar functions
- for global use
]]--

Meta = {}

function Meta:clear_track(t)
	self:paste_onto_track(t,self:get_track_copy(0))
	post('cleared track '..t)
end

function Meta:clear_page(t,p)
	self:paste_onto_page(t,p,self:get_page_copy(0,p))
	post('cleared '..p..' page on t'..t)
end

function Meta:make_scale()
	local table_from_params = {}
	for i=1,7 do
		table.insert(table_from_params,params:get('scale_'..params:get('scale_num')..'_deg_'..i))
	end
	local short_scale = {0} -- first ix always 0
	-- params:set('root_note',table_from_params[1])
	for i=2,7 do
		short_scale[i] = short_scale[i-1] + table_from_params[i]
	end
	local long_scale = {}
	for i=0,12 do
		for j=1,7 do
			table.insert(long_scale,short_scale[j]+(i*12))
		end
	end
	return long_scale
end

function Meta:resolve_pitches()
	for t=1,NUM_TRACKS do
		local n = data:get_step_val(t,'note',data:get_page_val(t,'note','pos'))
		n = n + data:get_step_val(t,'transpose',data:get_page_val(t,'transpose','pos'))-1
		n = n + 7*(data:get_step_val(t,'octave',data:get_page_val(t,'octave','pos')) + (data:get_track_val(t,'octave_shift')-1))
		if params:get('stretchable_t'..t) == 1 then
			n = util.round(n*((params:get('stretch')/64)+1))
		end
		if params:get('pushable_t'..t) == 1 then
			n = n + params:get('push')
		end

		local s = self:make_scale()
		n = s[util.clamp(n,1,#s)]
		n = n + params:get('root_note')

		value_buffer[t].note = n
	end
end

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
		post('cued: '..get_display_page_name()..' divisor: '..division_names[new_val])
	else
		data:set_page_val(track,page,'divisor',new_val)
		post(get_display_page_name()..' divisor: '..division_names[new_val])
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
		if (p == 'trig' or p == 'note') and params:get('note_sync') == 1 then
			data:set_page_val(track,'note','loop_first',f)
			data:set_page_val(track,'note','loop_last',l)
			data:set_page_val(track,'trig','loop_first',f)
			data:set_page_val(track,'trig','loop_last',l)
			post('t'..track..' trig & note loops: ['..f..'-'..l..']')
		else
			data:set_page_val(track,p,'loop_first',f)
			data:set_page_val(track,p,'loop_last',l)
			post('t'..track..' '..get_display_page_name()..' loop: ['..f..'-'..l..']')
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

function Meta:get_page_copy(t,page,pattern)
	data.pattern = p and p or ap()
	local r = {}
	local empty = t==0
	r['pos'] = empty and 1 or data:get_page_val(t,page,'pos')
	r['loop_first'] = empty and 1 or data:get_page_val(t,page,'loop_first')
	r['loop_last'] = empty and 6 or data:get_page_val(t,page,'loop_last')
	r['divisor'] = empty and 1 or data:get_page_val(t,page,'divisor')
	r['cued_divisor'] = empty and 0 or data:get_page_val(t,page,'cued_divisor')
	r['counter'] = empty and 1 or data:get_page_val(t,page,'counter')
	r.vals = {}
	r.probs = {}
	if page == 'retrig' then
		r.subtrig_counts = {}
		r.subtrigs = {}
	end
	for i=1,16 do
		table.insert(r.vals,empty and 0 or data:get_step_val(t,page,i))
		table.insert(r.probs,empty and 4 or data:get_unique(t,page..'_prob',i))
		if v == 'retrig' then
			table.insert(r.subtrig_counts,empty and 1 or data:get_unique(t,'subtrig_count',i))
			table.insert(r.subtrigs,{})
			for j=1,5 do
				table.insert(r.subtrigs[i], empty and (j==1 and 1 or 0) or data:get_unique(t,'subtrig',i,j)) 
			end
		end
	end
	data.pattern = ap()
	return r
end

function Meta:get_track_copy(t,p)
	data.pattern = p and p or ap()
	local r = {}
	for _,v in pairs(pages_with_steps) do
		r[v] = self:get_page_copy(t,v)
	end
	data.pattern = ap()
	return r
end

function Meta:paste_onto_page(t,page,page_table,pattern)
	data.pattern = p and p or ap()
	data:set_page_val(t,page,'pos',page_table.pos)
	data:set_page_val(t,page,'loop_first',page_table.loop_first)
	data:set_page_val(t,page,'loop_last',page_table.loop_last)
	data:set_page_val(t,page,'divisor',page_table.divisor)
	data:set_page_val(t,page,'cued_divisor',page_table.cued_divisor)
	data:set_page_val(t,page,'counter',page_table.counter)
	for i=1,16 do
		data:set_step_val(t,page,i,page_table.vals[i])
		data:set_unique(t,page..'_prob',i,page_table.probs[i])
		if v == 'retrig' then
			for j=1,5 do
				data:set_unique(t,'subtrig',i,j,page_table.subtrigs[j])
			end
		end
	end
	data.pattern = ap()
end

function Meta:paste_onto_track(t,track_table,p)
	data.pattern = p and p or ap()
	for _,v in pairs(pages_with_steps) do
		self:paste_onto_page(t,v,track_table[v],p)
	end
	post('pasted on track '..t)
	data.pattern = ap()
end

return Meta