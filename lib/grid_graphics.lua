--[[
WHAT GOES IN THIS FILE:
- everything related to how grid looks
]]--

local matrix_status, matrix = pcall(require, 'matrix/lib/matrix')
if not matrix_status then matrix = nil end

Graphics = {}

function Graphics:trig()
	local l = OFF;
	for t=1,NUM_TRACKS do
		for x=1,16 do
			l = OFF
			local this_trig_on = data:get_step_val(t,'trig',x) == 1
			local oob = out_of_bounds(t,'trig',x)
			if this_trig_on then
				if oob then
					l = MED
				else
					l = HIGH
				end
			else
				if oob then
					l = OFF
				else
					l = LOW
				end
			end

			if x == data:get_pos(t,'trig') and data:get_global_val('playing') == 1 then
				
				l = highlight(l)
			end
			if get_mod_key() == 'loop' and not oob then
				l = highlight(l)
			end
			g:led(x,t,l)
		end
	end
end

function Graphics:render()
	waver_flipflop = not waver_flipflop
	if waver_flipflop then
		wavery_light = wavery_light + waver_dir
		if wavery_light > MED+1 then
			waver_dir = -1
		elseif wavery_light < MED-1 then
			waver_dir = 1
		end
	end

	g:all(0)

	-- \/\/ these are in order of precedence \/\/
	local p = get_page_name()
	if get_overlay() == 'time' then self:config_1()
	elseif get_overlay() == 'options' then self:config_2()
	elseif get_overlay() == 'patchers' then self:patchers()
	elseif p == 'scale' then 
		if get_script_mode() == 'classic' then
			self:classic_scale()
		elseif get_script_mode() == 'extended' then
			self:extended_scale()
		end
	elseif p == 'track options' then
		self:track_options()
	elseif p == 'pattern' then 
		if data:get_global_val('ms_active') == 1 then
			self:meta_sequence()
		else
			self:pattern()
		end
	elseif data:get_global_val('mod') == 3 then self:time()
	elseif data:get_global_val('mod') == 4 then self:prob()
	elseif p == 'trig' then self:trig()
	elseif p == 'retrig' then self:retrig()
	elseif p == 'note' then self:note()
	elseif p == 'transpose' then self:transpose()
	elseif p == 'octave' then self:octave()
	elseif p == 'slide' then self:slide()
	elseif p == 'gate' then self:gate()
	elseif p == 'velocity' then self:velocity()
	end

	if get_overlay() == 'none' then 
		self:tracks()
		self:pages()
		self:modifiers()
	end

	g:refresh()
end

-- function Graphics:patchers()
-- 	local l;
-- 	l = (kbuf[2][6] or kbuf[1][7] or kbuf[2][7] or kbuf[2][8]) and HIGH or LOW
-- 	g:led(2,6,l); g:led(1,7,l); g:led(2,8,l)

-- 	l = (kbuf[15][6] or kbuf[16][7] or kbuf[15][7] or kbuf[15][8]) and HIGH or LOW
-- 	g:led(15,6,l); g:led(16,7,l); g:led(15,8,l)

-- 	for x=7,10 do g:led(x,7, LOW) end

-- 	if params:string('patcher') == 'advance triggers' then
-- 		self:advance_triggers_patcher()
-- 	end
-- end

-- function Graphics:advance_triggers_patcher()
-- 	for t=1,NUM_FULL_TRACKS do
-- 		g:led(1,t+1,matrix:get('trig_t'..t)==1 and HIGH or MED)
-- 	end

-- 	for k,v in ipairs(trig_sources) do
-- 		g:led(k+1,1,matrix:get(v)==1 and HIGH or MED)
-- 	end
-- end

function Graphics:config_1()
	local l
	-- note div sync
	l = data:get_global_val('note_div_sync') == 1 and HIGH or MED
	for i=1,4 do g:led(i,5,l) end
	g:led(1,6,l);g:led(4,6,l);g:led(1,7,l);g:led(4,7,l)
	for i=1,4 do g:led(i,8,l) end

	-- div cue
	l = data:get_global_val('div_cue') == 1 and HIGH or MED
	g:led(8,7,l);g:led(9,7,l);g:led(8,8,l);g:led(9,8,l)

	-- div sync
	l = data:get_global_val('div_sync') == 2 and HIGH or MED
	g:led(13,6,l)
	l = data:get_global_val('div_sync') == 3 and HIGH or MED
	for i=1,4 do
		g:led(12+i,8,l)
	end

	-- timing inc/dec keysets
	g:led(7,5,HIGH)
	g:led(8,5,MED)
	g:led(9,5,MED)
	g:led(10,5,HIGH)

	-- arrows
	if kbuf[7][5] then 
		g:led(7,4,HIGH)
		g:led(6,5,HIGH)
		g:led(7,6,HIGH)
	end
	if kbuf[8][5] then
		g:led(8,4,MED)
		g:led(8,6,MED)
	end
	if kbuf[9][5] then
		g:led(9,4,MED)
		g:led(9,6,MED)
	end
	if kbuf[10][5] then
		g:led(10,4,HIGH)
		g:led(11,5,HIGH)
		g:led(10,6,HIGH)
	end

	g:led(pulse_indicator,1,HIGH)

	self:time(data:get_global_val('clock_div'))

end

function Graphics:config_2()
	-- note sync
	l = data:get_global_val('note_sync') == 1 and HIGH or MED
	for i=1,4 do g:led(i+2,3,l) end
	g:led(3,4,l);g:led(6,4,l);g:led(3,5,l);g:led(6,5,l)
	for i=1,4 do g:led(i+2,6,l) end

	-- loop sync
	l = data:get_global_val('loop_sync') == 2 and HIGH or MED
	g:led(11,4,l)
	l = data:get_global_val('loop_sync') == 3 and HIGH or MED
	for i=1,4 do
		g:led(10+i,6,l)
	end



end

function Graphics:tracks()
	local l
	for i=1,4 do
		l = i == at() and HIGH or MED
		if data:get_track_val(i,'mute') == 1 then
			l = util.round(l/4)
		end
		g:led(i,8,l)
	end
end



function Graphics:pages()
	local p = data:get_global_val('page')
	local l
	for i=1,6 do
		l = (p == i) and HIGH or MED
		if p == i then
			l = HIGH
			if data:get_global_val('alt_page') == 1 then
				l = wavery_light
			end
		else
			l = MED
		end
		local x = i + 5
		if i > 4 then 
			x = i + 10
		end
		g:led(x,8,l) -- bottom row
	end
end

function Graphics:modifiers()
	local l;
	for i=1,3 do
		l = data:get_global_val('mod')-1 == i and HIGH or MED
		g:led(10+i,8,l)
	end
end

function Graphics:time(D)
	local l
	local d = D or data:get_page_val(at(),get_page_name(),'divisor')
	local amount = util.round(HIGH/d)
	for x=1,16 do
		if x > d then 
			l = LOW
		elseif x == d then
			l = HIGH
		else
			l = amount*x
		end
		g:led(x,2,l)
	end
	g:led(data:get_page_val(at(),get_page_name(),'counter'),1,MED)

	if get_script_mode() == 'classic' or D then return end
	for i=1,NUM_SYNC_GROUPS do
		local x1 = ((i-1)%4)+1
		local y1 = util.round_up(i/4)+4

		local l1, l2

		local x2 = x1 + 12
		local y2 = y1 - 2

		if just_pressed_track then
			l1 = data:get_track_val(at(),'loop_group')==i and HIGH or LOW
			l2 = data:get_track_val(at(),'div_group')==i and HIGH or LOW
		else
			l1 = data:get_page_val(at(),get_page_name(),'loop_group')==i and HIGH or LOW
			l2 = data:get_page_val(at(),get_page_name(),'div_group')==i and HIGH or LOW
		end
		g:led(x1,y1,l1)
		g:led(x2,y2,l2)
	end
	
	local l1, l2
	if just_pressed_track then
		l1 = data:get_track_val(at(),'loop_group')==0 and HIGH or LOW
		l2 = data:get_track_val(at(),'div_group')==0 and HIGH or LOW
	else
		l1 = data:get_page_val(at(),get_page_name(),'loop_group')==0 and HIGH or LOW
		l2 = data:get_page_val(at(),get_page_name(),'div_group')==0 and HIGH or LOW
	end

	g:led(7,5,l1)
	g:led(6,6,l1)
	g:led(8,6,l1)
	g:led(7,7,l1)

	g:led(10,3,l2)
	g:led(9,4,l2)
	g:led(11,4,l2)
	g:led(10,5,l2)
end

function Graphics:prob()
	for x=1,16 do
		local d = data:get_step_val(at(),get_page_name(),x,'prob')
		g:led(x,6,LOW)
		g:led(x,7-d,HIGH)
		g:led(x,1,data:get_pos(at(),get_page_name()) == x and MED or LOW)
	end
end

function Graphics:classic_scale()
	for i=1,16 do -- scale select
		local y = (i > 8) and 7 or 6
		local l = (data:get_global_val('scale_num') == i) and HIGH or MED
		g:led(((i-1) % 8)+1, y, l)
	end

	for t=1,4 do -- param clock buttons
		local l = (data:get_track_val(t,'param_clock') == 1) and HIGH or MED
		g:led(1,t,l)
	end

	for t=1,4 do -- trigger clock buttons
		local l = (data:get_track_val(t,'trigger_clock') == 1) and HIGH or MED
		g:led(2,t,l)
	end

	for t=1,4 do -- play modes
		g:led(3,t,LOW)
		g:led(9,t,LOW)
		for x=1,5 do
			local l = data:get_track_val(t,'play_mode') == x and HIGH or MED
			g:led(x+3,t,l)
		end
	end

	for i=2,7 do -- scale editor
		g:led(9,8-i,LOW)
		local d = data:get_global_val('scale_'..data:get_global_val('scale_num')..'_deg_'..i)
		g:led(9+d,8-i,HIGH)
		if temp_scale[i-1] ~= -1 then g:led(temp_scale[i-1]+9,8-i,MED) end
	end
	g:led(9,7,LOW)
	g:led(9+util.clamp(data:get_global_val('root_note'),0,7),7,HIGH)
end

function Graphics:extended_scale()
	for i=1,16 do -- scale select
		local x = (i > 8) and 2 or 1
		local l = (data:get_global_val('scale_num') == i) and HIGH or MED
		g:led(x, ((i-1) % 8)+1, l)
	end

	for i=2,7 do -- scale editor
		g:led(4,8-i,LOW)
		local d = data:get_global_val('scale_'..data:get_global_val('scale_num')..'_deg_'..i)
		g:led(4+d,8-i,HIGH)
		if temp_scale[i-1] ~= -1 then g:led(temp_scale[i-1]+4,8-i,MED) end
	end
	g:led(4,7,LOW)
	g:led(4+util.clamp(data:get_global_val('root_note'),0,7),7,HIGH)
end

function Graphics:track_options()

	for t=1,NUM_TRACKS do
		for k,v in ipairs(track_options) do
			local x = (t*3) + track_options_xes[k]
			local y = k
			local l = data:get_track_val(t,v) == 1 and HIGH or MED
			g:led(x,y,l)
		end
	end
end

function Graphics:meta_sequence()
	for x=1,16 do -- pattern bank
		local l = OFF
		if x == data:get_global_val('ms_pattern_'..data:get_global_val('ms_cursor')) then
			l = HIGH
		elseif x == last_touched_pattern and just_saved_pattern then
			l = wavery_light
		else
			l = LOW
		end
		g:led(x,1,l)
	end

	for x=1,16 do -- cue clock
		local l = OFF
		if x == data:get_global_val('pattern_quant_pos') then
			l = HIGH
		elseif x == data:get_global_val('pattern_quant') then
			l = MED
		elseif x < data:get_global_val('pattern_quant') then
			l = LOW
		end
		g:led(x,2,l)
	end

	for x=1,16 do -- duration
		local l = OFF
		if x == data:get_global_val('ms_duration_pos') then
			l = HIGH
		elseif x == data:get_global_val('ms_duration_'..data:get_global_val('ms_cursor')) then
			l = MED
		elseif x < data:get_global_val('ms_duration_'..data:get_global_val('ms_cursor')) then
			l = LOW
		end
		g:led(x,7,l)
	end

	for x=1,16 do
		for y=1,4 do
			local n = x+((y-1)*16)
			local l = OFF
			local oob = not ((n>=data:get_global_val('ms_first')) and (n<=data:get_global_val('ms_last')))
			if n == data:get_global_val('ms_cursor') then
				l = HIGH
			elseif n == data:get_global_val('ms_pos') then
				-- l = data:get_global_val('playing') == 1 and wavery_light or MED 
				l = MED
			elseif not oob then
				l = LOW
				if get_mod_key() == 'loop' then l = highlight(l) end
			end
			g:led(x,y+2,l)
		end
	end
end

function Graphics:pattern()
	for x=1,16 do -- pattern bank
		local l = OFF
		if x == data:get_global_val('active_pattern') then
			l = HIGH
		elseif x == data:get_global_val('cued_pattern') then
			l = wavery_light
		elseif x == last_touched_pattern and just_saved_pattern then
			l = wavery_light
		else
			l = LOW
		end
		g:led(x,1,l)
	end

	for x=1,16 do -- cue clock
		local l = OFF
		if x == data:get_global_val('pattern_quant_pos') then
			l = HIGH
		elseif x == data:get_global_val('pattern_quant') then
			l = MED
		elseif x < data:get_global_val('pattern_quant') then
			l = LOW
		end
		g:led(x,2,l)
	end
end

function Graphics:retrig()
	for x=1,16 do
		for y=1,7 do
			local l = OFF
			local oob = out_of_bounds(at(),'retrig',x)
			if y == 1 or y == 7 then
				l = kbuf[x][y] and HIGH or LOW 
				if data:get_pos(at(),'retrig') == x and data:get_global_val('playing') == 1 then
					l = highlight(l)
				end
			else
				if data:get_step_val(at(),'retrig',x) >= 7-y then
					if data:get_subtrig(at(),x,7-y)==1 then
						l = oob and MED or HIGH
					else
						l = oob and LOW or MED
					end
				end
				if data:get_global_val('mod') == 2 and not out_of_bounds(at(),'retrig',x) then
					l = highlight(l)
				end
			end
			g:led(x,y,l)
		end
	end
end

function Graphics:note()
	local l
	for x=1,16 do
		local d = data:get_step_val(at(),'note',x)
		if x == data:get_pos(at(),'note') and data:get_global_val('playing') == 1 then 
			l = LOW
		else
			l = OFF
		end
		for y=1,7 do
			local ly = l
			if y == d then
				ly = out_of_bounds(at(),'note',x) and LOW or HIGH
				if data:get_global_val('note_sync') == 1 and data:get_step_val(at(),'trig',x) == 0 then
					ly = out_of_bounds(at(),'note',x) and dim(LOW) or LOW
				end
			end
			if get_mod_key() == 'loop' and not out_of_bounds(at(),'note',x) then
				ly = highlight(ly)
			end
			g:led(x,8-y,ly)
		end
	end
end

function Graphics:transpose() -- identical to above, might want to fold them together
	local l
	for x=1,16 do
		local d = data:get_step_val(at(),'transpose',x)
		if x == data:get_pos(at(),'transpose') and data:get_global_val('playing') == 1 then 
			l = LOW
		else
			l = OFF
		end
		for y=1,7 do
			local ly = l
			if y == d then
				ly = out_of_bounds(at(),'transpose',x) and LOW or HIGH
			end
			if get_mod_key() == 'loop' and not out_of_bounds(at(),'transpose',x) then
				ly = highlight(ly)
			end
			g:led(x,8-y,ly)
		end
	end
end

function Graphics:octave()
	for i=1,8 do
		g:led(i,1,data:get_track_val(at(),'octave_shift')==i and HIGH or MED)
	end
	for x=1,16 do
		local d = data:get_step_val(at(),'octave',x)
		local oob = out_of_bounds(at(),'octave',x)
		for i=1,6 do
			local l = OFF
			if oob then
				if i == d then 
					l = MED
				else
					l = OFF
				end
			else
				if i < d then
					l = LOW
				elseif i == d then
					l = HIGH
				elseif i > d then
					l = OFF
				end
			end
			if get_mod_key() == 'loop' and (not oob) then
				l = highlight(l)
			end
			if x == data:get_pos(at(),'octave') and data:get_global_val('playing') == 1 then
				l = highlight(l)
			end
			g:led(x,8-i,l)
		end
	end
end

function Graphics:slide()
	for x=1,16 do
		local l = OFF
		local d = data:get_step_val(at(),'slide',x)
		local oob = out_of_bounds(at(),'slide',x)
		local l_accum = 0
		local l_delta = util.round(HIGH/d)
		for y=1,7 do
			if y > d then
				l = OFF
			elseif y == d then
				if oob then
					l = MED
				else
					l = HIGH
				end
			elseif y < d then
				if oob then
					l = LOW
				else
					l_accum = l_accum + l_delta
					l = l_accum
				end
			end
			if get_mod_key() == 'loop' and not oob then
				l = highlight(l)
			end
			if x == data:get_pos(at(),'slide') and data:get_global_val('playing') == 1 then
				l = highlight(l)
			end
			g:led(x,8-y,l)
		end
	end
end

function Graphics:gate()
	local s = data:get_track_val(at(),'gate_shift')
	for i=1,s do
		local l = LOW
		if i == s then
			l = HIGH
		elseif i > s then
			l = OFF
		end
		g:led(i,1,l)
	end

	for x=1,16 do
		local l = OFF
		local d = data:get_step_val(at(),'gate',x)
		local oob = out_of_bounds(at(),'gate',x)
		local l_accum = 0
		local l_delta = util.round(HIGH/d)
		for y=1,6 do
			if y > d then
				l = OFF
			elseif y == d then
				if oob then
					l = MED
				else
					l = HIGH
				end
			elseif y < d then
				if oob then
					l = LOW
				else
					l_accum = l_accum + l_delta
					l = l_accum
				end
			end
			if get_mod_key() == 'loop' and not oob then
				l = highlight(l)
			end
			if x == data:get_pos(at(),'gate') and data:get_global_val('playing') == 1 then
				l = highlight(l)
			end
			g:led(x,1+y,l)
		end
	end
end

function Graphics:velocity()
	for x=1,16 do
		local l = OFF
		local d = data:get_step_val(at(),'velocity',x)
		local oob = out_of_bounds(at(),'velocity',x)
		local l_accum = 0
		local l_delta = util.round(HIGH/d)
		for y=1,7 do
			if y > d then
				l = OFF
			elseif y == d then
				if oob then
					l = MED
				else
					l = HIGH
				end
			elseif y < d then
				if oob then
					l = LOW
				else
					l_accum = l_accum + l_delta
					l = l_accum
				end
			end
			if get_mod_key() == 'loop' and not oob then
				l = highlight(l)
			end
			if x == data:get_pos(at(),'velocity') and data:get_global_val('playing') == 1 then
				l = highlight(l)
			end
			g:led(x,8-y,l)
		end
	end
end

return Graphics