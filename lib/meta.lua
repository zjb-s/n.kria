--[[
WHAT GOES IN THIS FILE:
- utility, sanity and sugar functions
- for global use
]]--

local status, matrix = pcall(require, 'matrix/lib/matrix')
if not status then matrix = nil end

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
		local scale_num = data:get_global_val('scale_num')
		table.insert(table_from_params,data:get_scale_degree(scale_num, i))
	end
	local short_scale = {0} -- first ix always 0
	for i=2,7 do
		short_scale[i] = short_scale[i-1] + table_from_params[i]
	end
	for i=1,6 do
		if temp_scale[i] ~= -1 then
			short_scale[i+1] = short_scale[i] + temp_scale[i]
		end
	end
	local long_scale = {}
	for i=0,12 do
		for j=1,7 do
			table.insert(long_scale,short_scale[j]+(i*12))
		end
	end
	return long_scale
end

function Meta:update_last_notes()
	for t=1,NUM_TRACKS do
		local b = value_buffer[t]
		local n = b.note
		if matrix ~= nil then
			matrix:set("note_t"..t, (n-1)/6)
		end
	end
	for t=1,NUM_TRACKS do
		local b = value_buffer[t]
		local n = b.note
		n = n + b.transpose-1
		last_notes_raw[t] = n
		-- The "stretch" parameter attempts to extend a melody around its
		-- center. We assume the center is going to be the root note
		-- of octave 3, not counting the octave shift of the track.

		-- Subtract three octaves before stretch
		n = n + 7*(b.octave - 3)
		if data:get_track_val(t,'stretchable') == 1 then
			n = util.round((n-1)*((data:get_global_val('stretch')/8)+1)) + 1
		end
		-- Add them back after.
		n = n + 7*(3 + data:get_track_val(t,'octave_shift')-1)

		if data:get_track_val(t,'pushable') == 1 then
			n = n + data:get_global_val('push')
		end

		local s = self:make_scale()
		n = s[util.clamp(n,1,#s)]
		n = n + data:get_global_val('root_note')

		last_notes[t] = n
	end
end

function Meta:toggle_subtrig(track,step,subtrig)
	data:set_subtrig(track,step,subtrig,(data:get_subtrig(track,step,subtrig)==1 and 0 or 1))
	for i=data:get_step_val(track,'retrig',step),1,-1 do
		if data:get_subtrig(track,step,i)==0 then
			self:delta_subtrig_count(track,step,-1)
		else
			break
		end
	end
end

function Meta:delta_subtrig_count(track,step,delta)
	self:edit_subtrig_count(track,step,data:get_step_val(track,'retrig',step)+delta)
end

function Meta:edit_subtrig_count(track,step,new_val)
	data:set_step_val(track,'retrig',step,new_val)
	for i=1,5 do
		if	data:get_subtrig(track,step,i)==1 and i > new_val then
			data:set_subtrig(track,step,i,0)
		end
	end
	post('subtrig count s'..step..'t'..track..' '.. data:get_step_val(track,'retrig',step))
end

function Meta:edit_divisor(track,p,new_val)
	local group_to_edit = data:get_page_val(track,p,'div_group')
	if group_to_edit == 0 then
		group_to_edit = data:get_track_val(track,'div_group')
	end
	for t=1,NUM_TRACKS do
		for k,v in pairs(pages_with_steps) do
			local this_page_group = data:get_page_val(t,v,'div_group')
			if this_page_group == 0 then
				this_page_group = data:get_track_val(t,'div_group')
			end
			if this_page_group == group_to_edit then
				if data:get_global_val('div_cue')==1 then
					data:set_page_val(t,p,'cued_divisor',new_val)
				else
					data:set_page_val(t,v,'divisor',new_val)
				end
			end
		end
	end

	post('group '..group_to_edit..' divisor: '..new_val)
end

function Meta:edit_loop_classic(track, first, last)
	local f = math.min(first,last)
	local l = math.max(first,last)
	local p = get_page_name()
	local loopsync = div_sync_modes[data:get_global_val('loop_sync')]
	-- print(loopsync)

	if p == 'pattern' and params:get('ms_active') == 1 then
		params:set('ms_first',f)
		params:set('ms_last',l)
		post('meta-sequence loop: ['..f..'-'..l..']')
	elseif loopsync == 'none' then
		if (p == 'trig' or p == 'note') and data:get_global_val('note_sync') == 1 then
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
				if v == 'scale' or v == 'pattern' then break end
				data:set_page_val(t,v,'loop_first',f)
				data:set_page_val(t,v,'loop_last',l)
			end
		end
		post('all loops: ['..f..'-'..l..']')
	end
end


function Meta:edit_loop_extended(track, first, last, temporary)
	local f = math.min(first,last)
	local l = math.max(first,last)
	local p = get_page_name()
	-- print('t is',track)

	if p == 'pattern' and data:get_global_val('ms_active') == 1 then
		data:set_global_val('ms_first',f)
		data:set_global_val('ms_last',l)
		post('meta-sequence loop: ['..f..'-'..l..']')

	else
		local group_to_edit = data:get_page_val(track,p,'loop_group')
		if group_to_edit == 0 then
			group_to_edit = data:get_track_val(track,'loop_group')
		end
		if temporary == 'clear' and self.temp_looping_pages then
			for _, pg in ipairs(self.temp_looping_pages) do
				pg.temp_loop_first = nil
				pg.temp_loop_last = nil
				pg.temp_pos = nil
			end
			return
		end
		for t=1,NUM_TRACKS do
			for k,v in pairs(pages_with_steps) do
				local this_page_group = data:get_page_val(t,v,'loop_group')
				if this_page_group == 0 then
					this_page_group = data:get_track_val(t,'loop_group')
				end
				if this_page_group == group_to_edit then
					if temporary then
						data.tracks[t][v].temp_loop_first = f
						data.tracks[t][v].temp_loop_last = l
						self.temp_looping_pages = self.temp_looping_pages or {}
						table.insert(self.temp_looping_pages, data.tracks[t][v])
					else
						data:set_page_val(t,v,'loop_first',f)
						data:set_page_val(t,v,'loop_last',l)
					end
				end
			end
		end
		if temporary then
			post('group '..group_to_edit..' tmp loops: ['..f..'-'..l..']')
		else
			post('group '..group_to_edit..' loops: ['..f..'-'..l..']')
		end
	end
end

function Meta:switch_to_pattern(p)
	post('cued pattern '..p)
	data:set_global_val('cued_pattern',p)
end

function Meta:save_pattern_into_slot(slot)
	for t=1,NUM_TRACKS do 
		data.pattern = ap()
		local track_table = self:get_track_copy(t)
		data.pattern = slot
		self:paste_onto_track(t, track_table) 
		post('saved pattern to slot '..slot)
	end
	data.pattern = ap()
end

function Meta:get_page_copy(t,page)
	local r = {}
	local empty = t==0
	r['loop_first'] = empty and 1 or data:get_page_val(t,page,'loop_first')
	r['loop_last'] = empty and 6 or data:get_page_val(t,page,'loop_last')
	r['divisor'] = empty and 1 or data:get_page_val(t,page,'divisor')
	r['cued_divisor'] = empty and 0 or data:get_page_val(t,page,'cued_divisor')
	r.vals = {}
	r.probs = {}
	r.subtrigs = {}
	for i=1,16 do
		table.insert(r.vals,empty and 0 or data:get_step_val(t,page,i))
		table.insert(r.probs,empty and 4 or data:get_step_val(t,page,i, 'prob'))
		if empty then r.vals[i] = page_defaults[page].default end
		if page=='retrig' then
			table.insert(r.subtrigs,{})
			for st=1,5 do
				local v = st==1 and 1 or 0
				table.insert(r.subtrigs[i],empty and v or data:get_subtrig(t,i,st))
			end
		end
	end
	return r
end

function Meta:get_track_copy(t)
	local r = {}
	for _,v in pairs(pages_with_steps) do
		r[v] = self:get_page_copy(t,v)
	end
	return r
end

function Meta:paste_onto_page(t,page,page_table)
	data:set_page_val(t,page,'loop_first',page_table.loop_first)
	data:set_page_val(t,page,'loop_last',page_table.loop_last)
	data:set_page_val(t,page,'divisor',page_table.divisor)
	data:set_page_val(t,page,'cued_divisor',page_table.cued_divisor)
	for i=1,16 do
		data:set_step_val(t,page,i,page_table.vals[i])
		data:set_step_val(t,page,i,page_table.probs[i],'prob')
		if page == 'retrig' then
			for j=1,5 do
				data:set_subtrig(t,i,j,page_table.subtrigs[i][j])
			end
		end
	end
end

function Meta:paste_onto_track(t,track_table,p)
	for _,v in pairs(pages_with_steps) do
		self:paste_onto_page(t,v,track_table[v],p)
	end
	post('pasted on track '..t)
end

return Meta