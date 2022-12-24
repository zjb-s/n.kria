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
			post('global clock divisor: ' .. params:get('global_clock_div'))
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
	if kbuf[11][8] then -- loop mod
		params:delta('mute_t'..x, 1)
		post('t'..x..' '..((params:get('mute_t'..x) == 1) and 'mute' or 'unmute'))
	else
		params:set('active_track', x)
		post('track ' .. x)
	end
end

function gkeys:page_select(x,y,z,t)
	if x-5 == params:get('page') and x < 9 then -- if double-pressing...
		params:delta('alt_page',1)
	else
		params:set('page',page_map[x])
		params:set('alt_page',0)
	end
	post(get_page_name())
end

function gkeys:resolve_mod_keys(x,y,z,t) -- intentionally prioritizes leftmost held mod key
	if params:get('page') < 5 then
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
end

function gkeys:resolve_loop_keys(x,y,z,t)
	if z == 1 then -- press
		if loop_first == -1 then
			loop_first = x
		else
			loop_last = x
			edit_loop(t,loop_first, loop_last)
		end
	else -- release
		if loop_last == -1 then
			edit_loop(t,loop_first, loop_first)
		else
			for i=1,16 do
				if kbuf[i][y] then
					break
				end
				if i == 16 then
					loop_first = -1
				end
			end
		end
		for i=1,16 do
			if kbuf[i][y] then
				break
			end
			if i == 16 then
				loop_first = -1
				loop_last = -1
			end
		end
	end
end

function gkeys:time_mod(x,y,z,t)
	-- todo finish post implementation
	if z == 1 and y == 2 then

		local g1 = params:get('note_div_sync')
		local g2 = params:get('div_sync')
		local pn = get_page_name()

		if g1 == 0 and g2 == 1 then -- off/none
			params:set('divisor_'..pn..'_t'..at(),x)
			post(pn .. ' time divisor: ' .. params:get('divisor_'..pn..'_t'..at()))
		elseif g1 == 1 and g2 == 1 then -- on/none
			if pn == 'trig' or pn == 'note' then
				params:set('divisor_trig_t'..at(),x)
				params:set('divisor_note_t'..at(),x)
			else
				params:set('divisor_'..pn..'_t'..at(),x)
			end
		elseif g1 == 0 and g2 == 2 then --off/track
			for _,v in ipairs(combined_page_list) do
				if v ~= 'scale' and v ~= 'patterns' then
					params:set('divisor_'..v..'_t'..at(),x)
				end
			end
		elseif g1 == 1 and g2 == 2 then -- on/track
			if pn == 'trig' or pn == 'note' then
				params:set('divisor_trig_t'..at(),x)
				params:set('divisor_note_t'..at(),x)
			else
				for _,v in ipairs(combined_page_list) do
					if v ~= 'trig' and v ~= 'note' and v ~= 'scale' and v ~= 'patterns' then
						params:set('divisor_'..v..'_t'..at(),x)
					end
				end
			end
		elseif g1 == 0 and g2 == 3 then -- off/all
			for t=1,NUM_TRACKS do
				for _,v in ipairs(combined_page_list) do
					if v ~= 'scale' and v ~= 'patterns' then
						params:set('divisor_'..v..'_t'..t,x)
					end
				end
			end
		elseif g1 == 1 and g2 == 3 then -- on/all
			for t=1,NUM_TRACKS do
				if pn == 'trig' or pn == 'note' then
					params:set('divisor_trig_t'..t,x)
					params:set('divisor_note_t'..t,x)
				else
					for _,v in ipairs(combined_page_list) do
						if v ~= 'trig' and v ~= 'note' and v ~= 'scale' and v ~= 'patterns' then
							params:set('divisor_'..v..'_t'..t,x)
						end
					end
				end
			end
		end
	end
end

function gkeys:prob_mod(x,y,z,t)
	if z == 1 and y > 2 and y < 7 then
		params:set('data_'..get_page_name()..'_prob_'..x..'_t'..at(),7-y)
		-- todo finish probability implementation
		post('odds: '.. 7-y .. '%')
	end
end

function gkeys:scale_overlay(x,y,z,t)
	if x < 9 and y > 5 and y < 8 and z == 1 then -- scale select
		local n = x + (y-6) * 8
		params:set('scale_num',n)
		post('selected scale '..n)

	elseif x > 1 and x < 7 and y < 5 and z == 1 then -- play modes
		params:set('playmode_t'..y, x-1)
		post('t'..y..' playmode: '..play_modes[x-1])

	elseif x > 8 and z == 1 then -- scale editor
		params:set('scale_'..params:get('scale_num')..'_deg_'..8-y, x-9)

	end
end

function gkeys:trig_page(x,y,z,t)
	params:delta('data_trig_'..x..'_t'..t, 1)
	post('trig '..x..' '.. (params:get('data_trig_'..x..'_t'..t) == 1 and 'on' or 'off'))
end

function gkeys:retrig_page(x,y,z,t)
	if params:get('data_retrig_'..x..'_t'..t) == 7-y then
		params:set('data_retrig_'..x..'_t'..t, -1)
	else
		params:set('data_retrig_'..x..'_t'..t, (7 - y))
	end
	-- todo finish retrig implementation
end

function gkeys:note_page(x,y,z,t)
	params:set('data_note_'..x..'_t'..t, 8 - y)
	post('note '..x..': '..8-y)
end

function gkeys:transpose_page(x,y,z,t)
	params:set('data_transpose_'..x..'_t'..t, 8 - y)
	post('transpose '..x..': '..8-y)
end

function gkeys:octave_page(x,y,z,t)
	if y > 1 and y < 8 then
		params:set('data_octave_'..x..'_t'..t, 8 - y)
		post('octave '..x..': '..8-y)
	elseif y == 1 and x <= 5 then
		params:set('data_octave_shift_t'..t, x)
		post('t'..at()..' octave shift: '..x)
	end
end

function gkeys:slide_page(x,y,z,t)
	params:set('data_slide_'..x..'_t'..t, 8 - y)
	post('slide '..x..': '..8-y)
end

function gkeys:gate_page(x,y,z,t)
	if y > 1 and y < 8 then
		params:set('data_gate_'..x..'_t'..t, (-1)+y)
		post('gate duration '..x..': '..(-1)+y)
	elseif y == 1 then
		params:set('data_gate_shift_t'..t,x)
		post('t'..at()..' duration multiplier: '..x)
	end
end

function gkeys:key(x,y,z)
	--print(x,y,z,t)
	kbuf[x][y] = (z == 1)
	local t
	if get_page_name() == 'trig' then
		t = util.clamp(y,1,NUM_TRACKS)
	else
		t = params:get('active_track')
	end

	-- key processing
	if params:get('overlay') == 2 then
		self:time_overlay(x,y,z,t)
	elseif params:get('overlay') == 3 then
		self:config_overlay(x,y,z,t)
	elseif params:get('overlay') == 1 then -- no overlay
		if 	z == 1 and y == 8 and x <= NUM_TRACKS then
			self:track_select(x,y,z,t)
		elseif z == 1 and y == 8 and ((x >= 6 and x <= 9) or x > 14) then
			self:page_select(x,y,z,t)
		elseif y == 8 and x >= 11 and x <= 13 then
			self:resolve_mod_keys()
		elseif y <= 7 then -- main field
			if get_mod_key() == 'loop' then
				self:resolve_loop_keys(x,y,z,t)
			elseif get_mod_key() == 'time' then
				self:time_mod(x,y,z,t)
			elseif get_mod_key() == 'prob' then
				self:prob_mod(x,y,z,t)
			elseif get_page_name() == 'scale' then
				self:scale_overlay(x,y,z,t)
			else -- loop mod not held
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
					end
				end
			end
		end
	end
end

return gkeys