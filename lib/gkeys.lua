--[[
WHAT GOES IN THIS FILE:
- everything related to pressing buttons on grid
]]--

gkeys = {}

function gkeys:time_overlay(x,y,z,t)
	if z == 1 then
		if x < 5 and y > 4 then -- glyph 1
			params:delta('note_div_sync',1)
			post('note division sync '..(params:get('note_div_sync') == 1 and 'on' or 'off'))
		elseif x > 7 and x < 10 and y > 6 then -- glyph 2
			params:delta('div_cue',1)
			post('division cueing '..(params:get('div_cue') == 1 and 'on' or 'off'))
		elseif x == 13 and y == 6 then -- glyph 3 track key
			params:set('div_sync', params:get('div_sync') == 2 and 1 or 2)
			post('division sync ' .. (params:get('div_sync') == 2 and 'track' or 'off'))
		elseif x > 12 and y == 8 then -- glyph 3 all keys
			params:set('div_sync', params:get('div_sync') == 3 and 1 or 3)
			post('division sync ' .. (params:get('div_sync') == 3 and 'all' or 'off'))
		elseif y == 5 and (x == 7 or x == 10) then -- coarse time adjustment
			params:delta('clock_tempo',(x == 7 and -8 or 8))
			post('tempo '..(x == 7 and '-' or '+')..'8bpm')
		elseif y == 5 and x > 7 and x < 10 then -- fine time adjustment
			params:delta('clock_tempo',(x == 8 and -1 or 1))
			post('tempo '..(x == 8 and '-' or '+')..'1bpm')
		elseif y == 2 then
			params:set('global_clock_div',x)
			post('global clock divisor: ' .. division_names[params:get('global_clock_div')])
		end
	end
end

function gkeys:config_overlay(x,y,z,t)
	if z == 1 then
		if x > 2 and x < 7 and y > 2 and y < 7 then -- left glyph
			params:delta('note_sync',1)
			post('note sync '..(params:get('note_sync') == 1 and 'on' or 'off'))
		elseif x == 11 and y == 4 then -- glyph 2 track key
			params:set('loop_sync', params:get('loop_sync') == 2 and 1 or 2)
			post('loop sync ' .. (params:get('loop_sync') == 2 and 'track' or 'off'))
		elseif x > 10 and x < 15 and y == 6 then -- glyph 3 all keys
			params:set('loop_sync', params:get('loop_sync') == 3 and 1 or 3)
			post('loop sync ' .. (params:get('loop_sync') == 3 and 'all' or 'off'))
		end
	end
end

function gkeys:track_select(x,y,z,t)
	last_touched_track = x
	if get_mod_key() == 'loop' then
		data:delta_track_val(x,'mute',1)
		post('t'..x..' '..((data:get_track_val(x,'mute') == 1) and 'mute' or 'unmute'))
	else
		params:set('active_track', x)
		post('track ' .. x)
	end
end

function gkeys:page_select(x,y,z,t)
	if z==1 then 
		last_touched_page = x-5
		return
	elseif z==0 then
		if page_key_held() ~= 0 then
			return
		elseif just_pressed_clipboard_key then
			just_pressed_clipboard_key = false
			return
		end
	end

	if x-5 == params:get('page') and x < 10 then -- if double-pressing...
		params:delta('alt_page',1)
	else
		params:set('page',page_map[x])
		params:set('alt_page',0)
		if x == 16 and shift then
			params:delta('ms_active')
		end
	end
	post(get_display_page_name())
	if params:get('ms_active') == 1 and x == 16 then post('meta-sequence') end
end

function gkeys:resolve_mod_keys(x,y,z,t) -- intentionally prioritizes leftmost held mod key
	local mod_key_held = 0
	for i=1,3 do
		if kbuf[10+i][8] then
			mod_key_held = i
			break
		end
	end
	params:set('mod', mod_key_held+1)
	if mod_key_held == 0 then
		loop_first = -1
		loop_last = -1
	end
	if params:get('mod') ~= 1 then
		post(mod_names[params:get('mod')] .. ' mod')
	end
end

function gkeys:resolve_loop_keys(x,y,z,t)
	if z == 1 then -- press
		if loop_first == -1 then
			if get_page_name() == 'pattern' then
				loop_first = x+((y-3)*16)
			else
				loop_first = x
			end
		else
			if get_page_name() == 'pattern' then
				loop_last = x+((y-3)*16)
			else
				loop_last = x
			end
			meta:edit_loop(t,loop_first, loop_last)
		end
	else -- release
		if loop_last == -1 then
			meta:edit_loop(t,loop_first, loop_first)
		else
			for x=1,16 do
				for y=1,7 do
					if kbuf[x][y] then break end
				end
				if x == 16 then
					loop_first = -1
				end
			end
		end
		for x=1,16 do
			for y=1,7 do
				if kbuf[x][y] then break end
			end
			if i == 16 then
				loop_first = -1
				loop_last = -1
			end
		end
	end
end

function gkeys:time_mod(x,y,z,t)
	if z == 1 and y == 2 then

		local g1 = params:get('note_div_sync')
		local g2 = params:get('div_sync')
		local pn = get_page_name(false)

		if g1 == 0 and g2 == 1 then -- off/none
			meta:edit_divisor(at(),pn,x)
		elseif g1 == 1 and g2 == 1 then -- on/none
			if pn == 'trig' or pn == 'note' then
				meta:edit_divisor(at(),'trig',x)
				meta:edit_divisor(at(),'note',x)
			else
				meta:edit_divisor(at(),pn,x)
			end
		elseif g1 == 0 and g2 == 2 then --off/track
			for _,v in ipairs(combined_page_list) do
				if v ~= 'scale' and v ~= 'pattern' then
					meta:edit_divisor(at(),v,x)
				end
			end
		elseif g1 == 1 and g2 == 2 then -- on/track
			if pn == 'trig' or pn == 'note' then
				meta:edit_divisor(at(),'trig',x)
				meta:edit_divisor(at(),'note',x)
			else
				for _,v in ipairs(combined_page_list) do
					if v ~= 'trig' and v ~= 'note' and v ~= 'scale' and v ~= 'pattern' then
						meta:edit_divisor(at(),v,x)
					end
				end
			end
		elseif g1 == 0 and g2 == 3 then -- off/all
			for t=1,NUM_TRACKS do
				for _,v in ipairs(combined_page_list) do
					if v ~= 'scale' and v ~= 'pattern' then
						meta:edit_divisor(t,v,x)
					end
				end
			end
		elseif g1 == 1 and g2 == 3 then -- on/all
			for t=1,NUM_TRACKS do
				if pn == 'trig' or pn == 'note' then
					meta:edit_divisor(t,'trig',x)
					meta:edit_divisor(t,'note',x)
				else
					for _,v in ipairs(combined_page_list) do
						if v ~= 'trig' and v ~= 'note' and v ~= 'scale' and v ~= 'pattern' then
							meta:edit_divisor(t,v,x)
						end
					end
				end
			end
		end
	end
end

function gkeys:prob_mod(x,y,z,t)
	if z == 1 and y > 2 and y < 7 then
		--params:set('data_'..get_page_name()..'_prob_'..x..'_t'..at(),7-y)
		data:set_step_val(at(),get_page_name()..'_prob',x,7-y)
		post('odds: '.. prob_map[7-y] .. '%')
	end
end

function gkeys:scale_overlay(x,y,z,t)
	if x < 9 and y > 5 and y < 8 and z == 1 then -- scale select
		local n = x + (y-6) * 8
		params:set('scale_num',n)
		post('selected scale '..n)

	elseif x == 1 and y < 5 and z == 1 then -- trigger clock toggles
		data:delta_track_val(y,'trigger_clock',1)
		post('t'..t..' trigger clocking '..(data:get_track_val(y,'trigger_clock') == 1 and 'on' or 'off'))

	elseif x > 2 and x < 8 and y < 5 and z == 1 then -- play modes
		params:set('play_mode_t'..y, x-2)
		post('t'..y..' playmode: '..play_modes[x-2])

	elseif x > 8 and z == 1 then -- scale editor
		if y == 7 then
			params:set('root_note',x-9)
			post('root note: '..mu.note_num_to_name(params:get('root_note')))
			meta:make_scale()
			return
		end
		
		if  	(kbuf[params:get('scale_'..params:get('scale_num')..'_deg_'..8-y)+9][y]) 
			and (temp_scale[7-y] ~= x-9)
			and (params:get('scale_'..params:get('scale_num')..'_deg_'..8-y) ~= x-9) 
		then
			temp_scale[7-y] = x-9
			post('live-adjust '..7-y..': '..temp_scale[7-y])
		else
			params:set('scale_'..params:get('scale_num')..'_deg_'..8-y, x-9)
			temp_scale[7-y] = -1
			post('scale stride, degree '..8-y..': '..x-9)
		end
		meta:make_scale()
	end
end

function pattern_longpress_clock(x) -- here for compatibility/tutorialization, don't remove
	clock.sleep(0.5)
	if kbuf[x][1] then
		post('use shift+pattern to save!')
	end
end

function gkeys:pattern_overlay(x,y,z,t)
	if z == 1 then
		if y == 1 then
			if coros.pattern_longpress then clock.cancel(coros.pattern_longpress) end
			coros.pattern_longpress = clock.run(pattern_longpress_clock,x)
			if shift then
				meta:save_pattern_into_slot(x)
			else
				meta:switch_to_pattern(x)
			end
		elseif y == 2 then
			params:set('pattern_quant',x)
			post('cue clock: '..x)
		end
	end
end

function gkeys:meta_sequence(x,y,z,t)
	if z == 1 then
		if y == 1 then
			params:set('ms_pattern_'..params:get('ms_cursor'),x)
			post('meta step '..params:get('ms_cursor')..' pattern: '..params:get('ms_pattern_'..params:get('ms_cursor')))
		elseif y == 2 then
			params:set('pattern_quant',x)
			post('cue clock: '..x)
		elseif y > 2 and y < 7 then
			params:set('ms_cursor',x+((y-3)*16))
			last_touched_ms_step = x+((y-3)*16)
			post('meta-sequence cursor: '..params:get('ms_cursor'))
		elseif y == 7 then
			params:set('ms_duration_'..params:get('ms_cursor'),x)
			post('meta step '..params:get('ms_cursor')..' duration: '..params:get('ms_duration_'..params:get('ms_cursor')))
		end
	end
end

function gkeys:trig_page(x,y,z,t)
	data:delta_step_val(t,'trig',x,1)
	post('trig '..x..' '.. (data:get_step_val(t,'trig',x) == 1 and 'on' or 'off'))
end

function gkeys:retrig_page(x,y,z,t)
	if y == 1 or y == 7 then
		meta:delta_subtrig_count(t,x,(y==1 and 1 or -1))
	else
		if 7-y > data:get_step_val(t,'retrig',x) then
			data:set_step_val(t,'retrig',x,7-y)
		end 
		meta:toggle_subtrig(t,x,7-y)
		post('subtrig '..7-y..' '..(data:get_subtrig(t,x,7-y)==1 and 'on' or 'off'))
	end
end

function gkeys:note_page(x,y,z,t)
	if  data:get_step_val(t,'note',x) == 8-y and params:get('note_sync') == 1 then
		data:delta_step_val(t,'trig',x,1)
		post('note & trig '..x..': '..8-y)
	else
		data:set_step_val(t,'note',x,8-y)
		local n = mu.note_num_to_name(meta:make_scale()[(8-y)+params:get('root_note')])
		post('note '..x..': '..8-y.. ' ['..n..']')
	end
end

function gkeys:transpose_page(x,y,z,t)
	data:set_step_val(t,'transpose',x,8-y)
	post('transpose '..x..': '..8-y)
end

function gkeys:octave_page(x,y,z,t)
	if y > 1 and y < 8 then
		data:set_step_val(t,'octave',x,8-y)
		post('octave '..x..': '..8-y)
	elseif y == 1 and x < 9 then
		data:set_track_val(t,'octave_shift',x)
		post('t'..t..' octave shift: '..x-1)
	end
end

function gkeys:slide_page(x,y,z,t)
	data:set_step_val(t,'slide',x,8-y)
	local player = params:lookup_param("voice_t"..t):get_player()
	local description = player:describe()
	if description.supports_slew then
		post('slide '..x..': '..8-y)
	else
		post(description.modulate_description .. ' ' .. x .. ": "..8-y)
	end
end

function gkeys:gate_page(x,y,z,t)
	if y > 1 and y < 8 then
		data:set_step_val(t,'gate',x,(-1)+y)
		post('gate duration '..x..': '..(-1)+y)
	elseif y == 1 then
		data:set_track_val(t,'gate_shift',x)
		post('t'..at()..' duration multiplier: '..x)
	end
end

function gkeys:velocity_page(x,y,z,t)
	data:set_step_val(t,'velocity',x,8-y)
	post('velocity '..x..': '..8-y)
end

function gkeys:key(x,y,z)
	kbuf[x][y] = (z == 1)
	local t
	if get_page_name() == 'trig' then
		t = util.clamp(y,1,NUM_TRACKS)
	else
		t = params:get('active_track')
	end

	-- key processing
	if get_overlay() == 'time' then
		self:time_overlay(x,y,z,t)
	elseif get_overlay() == 'options' then
		self:config_overlay(x,y,z,t)
	elseif get_overlay() == 'none' then -- no overlay
		if 	z == 1 and y == 8 and x <= NUM_TRACKS then
			self:track_select(x,y,z,t)
		elseif y == 8 and ((x >= 6 and x <= 9) or x > 14) then
			self:page_select(x,y,z,t)
		elseif y == 8 and x >= 11 and x <= 13 then
			self:resolve_mod_keys()
		elseif y <= 7 then -- main field
			if get_page_name() == 'scale' then
				self:scale_overlay(x,y,z,t)
			elseif get_mod_key() == 'loop' then
				self:resolve_loop_keys(x,y,z,t)
			elseif get_page_name() == 'pattern' then
				if params:get('ms_active') == 1 then
					self:meta_sequence(x,y,z,t)
				else
					self:pattern_overlay(x,y,z,t)
				end
			elseif get_mod_key() == 'time' then
				self:time_mod(x,y,z,t)
			elseif get_mod_key() == 'prob' then
				self:prob_mod(x,y,z,t)
			else -- mods not held
				if z == 1 then
					if get_page_name() == 'trig' then
						self:trig_page(x,y,z,t)
					elseif get_page_name() == 'retrig' then
						self:retrig_page(x,y,z,t)
					elseif get_page_name() == 'note' then
						self:note_page(x,y,z,t)
					elseif get_page_name() == 'transpose' then
						self:transpose_page(x,y,z,t)
					elseif get_page_name() == 'octave' then
						self:octave_page(x,y,z,t)
					elseif get_page_name() == 'slide' then 
						self:slide_page(x,y,z,t)
					elseif get_page_name() == 'gate' then
						self:gate_page(x,y,z,t)
					elseif get_page_name() == 'velocity' then
						self:velocity_page(x,y,z,t)
					end
				end
			end
		end
	end
end

return gkeys