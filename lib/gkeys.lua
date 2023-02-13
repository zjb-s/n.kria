--[[
WHAT GOES IN THIS FILE:
- everything related to pressing buttons on grid
]]--

gkeys = {}

function gkeys:time_overlay(x,y,z,t)
	if z == 1 then
		if x < 5 and y > 4 then -- glyph 1
			data:delta_global_val('note_div_sync',1)
			post('note division sync '..(data:get_global_val('note_div_sync') == 1 and 'on' or 'off'))
		elseif x > 7 and x < 10 and y > 6 then -- glyph 2
			data:delta_global_val('div_cue',1)
			post('division cueing '..(data:get_global_val('div_cue') == 1 and 'on' or 'off'))
		elseif x == 13 and y == 6 then -- glyph 3 track key
			data:set_global_val('div_sync', data:get_global_val('div_sync') == 2 and 1 or 2)
			post('division sync ' .. (data:get_global_val('div_sync') == 2 and 'track' or 'off'))
		elseif x > 12 and y == 8 then -- glyph 3 all keys
			data:set_global_val('div_sync', data:get_global_val('div_sync') == 3 and 1 or 3)
			post('division sync ' .. (data:get_global_val('div_sync') == 3 and 'all' or 'off'))
		elseif y == 5 and (x == 7 or x == 10) then -- coarse time adjustment
			data:delta_global_val('clock_tempo',(x == 7 and -8 or 8))
			post('tempo '..(x == 7 and '-' or '+')..'8bpm')
		elseif y == 5 and x > 7 and x < 10 then -- fine time adjustment
			data:delta_global_val('clock_tempo',(x == 8 and -1 or 1))
			post('tempo '..(x == 8 and '-' or '+')..'1bpm')
		elseif y == 2 then
			data:set_global_val('global_clock_div',x)
			post('global clock divisor: ' .. division_names[data:get_global_val('global_clock_div')])
		end
	end
end

function gkeys:config_overlay(x,y,z,t)
	if z == 1 then
		if x > 2 and x < 7 and y > 2 and y < 7 then -- left glyph
			data:delta_global_val('note_sync',1)
			post('note sync '..(data:get_global_val('note_sync') == 1 and 'on' or 'off'))
		elseif x == 11 and y == 4 then -- glyph 2 track key
			data:set_global_val('loop_sync', data:get_global_val('loop_sync') == 2 and 1 or 2)
			post('loop sync ' .. (data:get_global_val('loop_sync') == 2 and 'track' or 'off'))
		elseif x > 10 and x < 15 and y == 6 then -- glyph 3 all keys
			data:set_global_val('loop_sync', data:get_global_val('loop_sync') == 3 and 1 or 3)
			post('loop sync ' .. (data:get_global_val('loop_sync') == 3 and 'all' or 'off'))
		end
	end
end

function gkeys:track_select(x,y,z,t)
	last_touched_track = x
	if get_mod_key() == 'loop' and z == 1 then
		data:delta_track_val(x,'mute',1)
		post('t'..x..' '..((data:get_track_val(x,'mute') == 1) and 'mute' or 'unmute'))
	elseif get_mod_key() == 'time' and z == 1 then
		set_active_track(x)
		just_pressed_track = true
	elseif z == 1 then
		set_active_track(x)
	elseif z == 0 then
		if not (kbuf[1][8] or kbuf[2][8] or kbuf[3][8] or kbuf[4][8]) then
			just_pressed_track = false
		end
	end
end

function gkeys:page_select(x,y,z,t)
	if z==1 then
		return
	elseif z==0 then
		if page_key_held() ~= 0 then
			return
		elseif just_pressed_clipboard_key then
			just_pressed_clipboard_key = false
			return
		end
	end

	if page_map[x] == data:get_global_val('page') then -- if double-pressing...
		if tab.contains({6,7,8,9},x)
		-- or (get_script_mode() == 'extended' and x == 15)
		then
			data:delta_global_val('alt_page',1)
		end
	else
		data:set_global_val('page',page_map[x])
		data:set_global_val('alt_page',0)
	end

	post(get_display_page_name())
	if get_display_page_name() == 'pattern' and data:get_global_val('ms_active') then
		post('metasequence')
	end
end

function gkeys:resolve_mod_keys(x,y,z,t) -- intentionally prioritizes leftmost held mod key
	local mod_key_held = 0
	for i=1,3 do
		if kbuf[10+i][8] then
			mod_key_held = i
			break
		end
	end
	data:set_global_val('mod', mod_key_held+1)
	if mod_key_held == 0 then
		loop_first = -1
		loop_last = -1
	end
	if data:get_global_val('mod') ~= 1 then
		post(mod_names[data:get_global_val('mod')] .. ' mod')
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
	if z == 0 then return end
	if y == 2 then
		meta:edit_divisor(at(),get_page_name(),x)
	end
	if get_script_mode() == 'classic' then return end
	if x > 10 and y > 3 and y < 7 then
		local n = (x-10)+((y-4)*5)
		if just_pressed_track then
			data:set_track_val(at(),'sync_group',n)
			post('t'..at()..' sync group: '..n)
		else
			data:set_page_val(at(),get_page_name(),'sync_group',n)
			post(get_page_name()..' sync group: '..n)
		end
	elseif x > 2 and x < 6 and y > 3 and y < 7 then
		if just_pressed_track then
			data:set_track_val(at(),'sync_group',0)
			post('t'..at()..' sync group: track/0')
		else
			data:set_page_val(at(),get_page_name(),'sync_group',0)
			post(get_page_name()..' group: track/0')
		end
	end
end

function gkeys:prob_mod(x,y,z,t) 
	if z == 1 and y > 2 and y < 7 then
		--data:set_global_val('data_'..get_page_name()..'_prob_'..x..'_t'..at(),7-y)
		data:set_step_val(at(),get_page_name()..'_prob',x,7-y)
		post('odds: '.. prob_map[7-y] .. '%')
	end
end

function gkeys:classic_scale(x,y,z,t)
	if x < 9 and y > 5 and y < 8 and z == 1 then -- scale select
		local n = x + (y-6) * 8
		data:set_global_val('scale_num',n)
		post('selected scale '..n)

	elseif x == 1 and y < 5 and z == 1 then
		data:delta_track_val(y,'param_clock',1)
		post('t'..y..' param clocking '..(data:get_track_val(y,'param_clock') == 1 and 'on' or 'off')) 

	elseif x == 2 and y < 5 and z == 1 then -- trigger clock toggles
		data:delta_track_val(y,'trigger_clock',1)
		post('t'..y..' trigger clocking '..(data:get_track_val(y,'trigger_clock') == 1 and 'on' or 'off'))

	elseif x > 3 and x < 9 and y < 5 and z == 1 then -- play modes
		data:set_global_val('play_mode_t'..y, x-3)
		post('t'..y..' playmode: '..play_modes[x-3])

	elseif x > 8 and z == 1 then -- scale editor
		if y == 7 then
			data:set_global_val('root_note',x-9)
			post('root note: '..mu.note_num_to_name(data:get_global_val('root_note')))
			meta:make_scale()
			return
		end
		
		if  	(kbuf[data:get_global_val('scale_'..data:get_global_val('scale_num')..'_deg_'..8-y)+9][y]) 
			and (temp_scale[7-y] ~= x-9)
			and (data:get_global_val('scale_'..data:get_global_val('scale_num')..'_deg_'..8-y) ~= x-9) 
		then
			temp_scale[7-y] = x-9
			post('live-adjust '..7-y..': '..temp_scale[7-y])
		else
			data:set_global_val('scale_'..data:get_global_val('scale_num')..'_deg_'..8-y, x-9)
			temp_scale[7-y] = -1
			post('scale stride, degree '..8-y..': '..x-9)
		end
		meta:make_scale()
	end
end

function gkeys:extended_scale(x,y,z,t)
	if x < 3 and z == 1 then -- scale select
		local n = y + (x-1) * 8
		data:set_global_val('scale_num',n)
		post('selected scale '..n)	

	elseif x > 3 and z == 1 then -- scale editor
		if y == 7 then
			data:set_global_val('root_note',x-4)
			post('root note: '..mu.note_num_to_name(data:get_global_val('root_note')))
			meta:make_scale()
			return
		end
		
		if  	(kbuf[data:get_global_val('scale_'..data:get_global_val('scale_num')..'_deg_'..8-y)+4][y]) 
			and (temp_scale[7-y] ~= x-4)
			and (data:get_global_val('scale_'..data:get_global_val('scale_num')..'_deg_'..8-y) ~= x-4) 
		then
			temp_scale[7-y] = x-4
			post('live-adjust '..7-y..': '..temp_scale[7-y])
		else
			data:set_global_val('scale_'..data:get_global_val('scale_num')..'_deg_'..8-y, x-4)
			temp_scale[7-y] = -1
			post('scale stride, degree '..8-y..': '..x-4)
		end
		meta:make_scale()
	end
end

function gkeys:track_options(x,y,z,t)
	if z == 1 then
		local column
		set_active_track(util.clamp(util.round_up((x-2)/3),1,4))
		data:delta_track_val(at(),track_options[y],1)
		post('track '..at()..' '..track_options[y]..' '..(data:get_track_val(at(),track_options[y])==1 and 'on' or 'off'))
	end
end

function gkeys:pattern_overlay(x,y,z,t)
	if y == 1 then
		if z == 1 then
			last_touched_pattern = x
			if coros.pattern_longpress then clock.cancel(coros.pattern_longpress) end 
			coros.pattern_longpress = clock.run(pattern_longpress_clock,last_touched_pattern)
		elseif z == 0 and (not just_saved_pattern) then 
			meta:switch_to_pattern(x) 
			just_saved_pattern = false 
		elseif z == 0 then
			just_saved_pattern = false
		end
	elseif y == 2 and z == 1 then
		data:set_global_val('pattern_quant',x)
		post('cue clock: '..x)
	elseif y == 7 and z == 1 and kbuf[16][8] then
		data:set_global_val('ms_active',1)
		post('meta-sequence on')
	end
end

function gkeys:meta_sequence(x,y,z,t)
	if y == 1 then
		if z == 1 then
			last_touched_pattern = x
			if coros.pattern_longpress then clock.cancel(coros.pattern_longpress) end 
			coros.pattern_longpress = clock.run(pattern_longpress_clock,last_touched_pattern)
		elseif z == 0 and (not just_saved_pattern) then 
			data:set_global_val('ms_pattern_'..data:get_global_val('ms_cursor'),x)
			post('meta step '..data:get_global_val('ms_cursor')..' pattern: '..data:get_global_val('ms_pattern_'..data:get_global_val('ms_cursor')))
			just_saved_pattern = false 
		elseif z == 0 then
			just_saved_pattern = false
		end
	elseif y == 2 and z == 1 then
		data:set_global_val('pattern_quant',x)
		post('cue clock: '..x)
	elseif y > 2 and y < 7 and z == 1 then
		data:set_global_val('ms_cursor',x+((y-3)*16))
		last_touched_ms_step = x+((y-3)*16)
		post('meta-sequence cursor: '..data:get_global_val('ms_cursor'))
	elseif y == 7 and z == 1 and not kbuf[16][8] then
		data:set_global_val('ms_duration_'..data:get_global_val('ms_cursor'),x)
		post('meta step '..data:get_global_val('ms_cursor')..' duration: '..data:get_global_val('ms_duration_'..data:get_global_val('ms_cursor')))
	elseif y == 7 and z == 1 and kbuf[16][8] then
		data:set_global_val('ms_active',0)
		post('meta-sequence off')
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
	if  data:get_step_val(t,'note',x) == 8-y and data:get_global_val('note_sync') == 1 then
		data:delta_step_val(t,'trig',x,1)
		post('note & trig '..x..': '..8-y)
	else
		data:set_step_val(t,'note',x,8-y)
		local n = mu.note_num_to_name(meta:make_scale()[(8-y)+data:get_global_val('root_note')])
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

function gkeys:patchers(x,y,z,t)
	if z == 1 and x<4 and y>5 then
		data:delta_global_val('patcher',-1)
	elseif z == 1 and x>13 and y>5 then
		data:delta_global_val('patcher',1)
	elseif z == 1 and tab.contains({6,7,8,9,10,11},x) and y==7 then
		set_overlay('none')
	elseif params:string('patcher') == 'advance triggers' then
		self:advance_triggers_patcher(x,y,z,t)
	end
end

function gkeys:advance_triggers_patcher(x,y,z,t)
	if x == 1 and tab.contains({2,3,4,5},y) then
		post('dest: advance t'..y-1)
	elseif z == 1 and y == 1 and x > 1 and x < #trig_sources+2 then
		post('source: '..trig_sources[x-1])
	end
end

function gkeys:key(x,y,z)
	print('grid:',x,y,z)
	kbuf[x][y] = (z == 1)
	local t
	if get_page_name() == 'trig' and y <= NUM_TRACKS then
		t = y
	else
		t = at()
	end

	-- key processing
	if get_overlay() == 'time' then
		self:time_overlay(x,y,z,t)
	elseif get_overlay() == 'options' then
		self:config_overlay(x,y,z,t)
	elseif get_overlay() == 'patchers' then
		self:patchers(x,y,z,t)
	elseif get_overlay() == 'none' then -- no overlay
		if y == 8 and tab.contains({5,10,14},x) and get_script_mode() == 'extended' then
			if kbuf[5][8] and kbuf[10][8] and kbuf[14][8] then 
				data:set_global_val('overlay',4)
				post('patcher: '..params:string('patcher'))
			end
		elseif y == 8 and tab.contains({1,2,3,4},x) then
			self:track_select(x,y,z,t)
		elseif y == 8 and tab.contains({6,7,8,9,15,16},x) then
			self:page_select(x,y,z,t)
		elseif y == 8 and tab.contains({11,12,13},x) then
			self:resolve_mod_keys()
		elseif y <= 7 then -- main field
			if get_page_name() == 'scale' then
				self:classic_scale(x,y,z,t)
				-- if get_script_mode() == 'classic' then
				-- 	self:classic_scale(x,y,z,t)
				-- else
				-- 	self:extended_scale(x,y,z,t)
				-- end
			-- elseif get_page_name() == 'track options' then
				-- self:track_options(x,y,z,t)
			elseif get_mod_key() == 'loop' then
				self:resolve_loop_keys(x,y,z,t)
			elseif get_page_name() == 'pattern' then
				if data:get_global_val('ms_active') == 1 then
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