--[[
WHAT GOES IN THIS FILE:
- everything related to how grid looks
]]--

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

			if x == data:get_page_val(t,'trig','pos') and params:get('playing') == 1 then
				
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

	g:all(0)

	-- \/\/ these are in order of precedence \/\/
	local p = get_page_name()
	if get_overlay() == 'time' then self:config_1()
	elseif get_overlay() == 'options' then self:config_2()
	elseif p == 'scale' then self:scale()
	elseif p == 'pattern' then 
		if params:get('ms_active') == 1 then
			self:meta_sequence()
		else
			self:pattern()
		end
	elseif params:get('mod') == 3 then self:time()
	elseif params:get('mod') == 4 then self:prob()
	elseif p == 'trig' then self:trig()
	elseif p == 'retrig' then self:retrig()
	elseif p == 'note' then self:note()
	elseif p == 'transpose' then self:transpose()
	elseif p == 'octave' then self:octave()
	elseif p == 'slide' then self:slide()
	elseif p == 'gate' then self:gate()
	end

	if get_overlay() == 'none' then 
		self:tracks()
		self:pages()
		self:modifiers()
	end

	g:refresh()
end

function Graphics:config_1()
	local l
	-- note div sync
	l = params:get('note_div_sync') == 1 and HIGH or MED
	for i=1,4 do g:led(i,5,l) end
	g:led(1,6,l);g:led(4,6,l);g:led(1,7,l);g:led(4,7,l)
	for i=1,4 do g:led(i,8,l) end

	-- div cue
	l = params:get('div_cue') == 1 and HIGH or MED
	g:led(8,7,l);g:led(9,7,l);g:led(8,8,l);g:led(9,8,l)

	-- div sync
	l = params:get('div_sync') == 2 and HIGH or MED
	g:led(13,6,l)
	l = params:get('div_sync') == 3 and HIGH or MED
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

	self:time(params:get('global_clock_div'))

end

function Graphics:config_2()
	-- note sync
	l = params:get('note_sync') == 1 and HIGH or MED
	for i=1,4 do g:led(i+2,3,l) end
	g:led(3,4,l);g:led(6,4,l);g:led(3,5,l);g:led(6,5,l)
	for i=1,4 do g:led(i+2,6,l) end

	-- loop sync
	l = params:get('loop_sync') == 2 and HIGH or MED
	g:led(11,4,l)
	l = params:get('loop_sync') == 3 and HIGH or MED
	for i=1,4 do
		g:led(10+i,6,l)
	end



end

function Graphics:tracks()
	local l
	for i=1,NUM_TRACKS do
		l = i == at() and HIGH or MED
		if data:get_track_val(i,'mute') == 1 then
			l = util.round(l/4)
		end
		g:led(i,8,l)
	end
end



function Graphics:pages()
	local p = params:get('page')
	local l
	for i=1,6 do
		l = (p == i) and HIGH or MED
		if p == i then
			l = HIGH
			if params:get('alt_page') == 1 then
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
		l = params:get('mod')-1 == i and HIGH or MED
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
end

function Graphics:prob()
	for x=1,16 do
		local d = data:get_step_val(at(),get_page_name()..'_prob',x)
		g:led(x,6,LOW)
		g:led(x,7-d,HIGH)
		g:led(x,1,data:get_page_val(at(),get_page_name(),'pos') == x and MED or LOW)
	end
end

function Graphics:scale()
	for i=1,16 do -- scale select
		local y = (i > 8) and 7 or 6
		local l = (params:get('scale_num') == i) and HIGH or MED
		g:led(((i-1) % 8)+1, y, l)
	end

	for t=1,4 do -- trigger clock buttons
		local l = (data:get_track_val(t,'trigger_clock') == 1) and HIGH or MED
		g:led(1,t,l)
	end

	for t=1,4 do -- play modes
		g:led(2,t,LOW)
		g:led(8,t,LOW)
		for x=1,5 do
			local l = data:get_track_val(t,'play_mode') == x and HIGH or MED
			g:led(x+2,t,l)
		end
	end

	for i=2,7 do -- scale editor
		g:led(9,8-i,LOW)
		local d = params:get('scale_'..params:get('scale_num')..'_deg_'..i)
		g:led(9+d,8-i,HIGH)
		if temp_scale[i-1] ~= -1 then g:led(temp_scale[i-1]+9,8-i,MED) end
	end
	g:led(9,7,LOW)
	g:led(9+util.clamp(params:get('root_note'),0,7),7,HIGH)
end

function Graphics:meta_sequence()
	for x=1,16 do -- pattern bank
		local l = OFF
		if x == params:get('ms_pattern_'..params:get('ms_cursor')) then
			l = HIGH
		else
			l = LOW
		end
		g:led(x,1,l)
	end

	for x=1,16 do -- cue clock
		local l = OFF
		if x == params:get('pattern_quant_pos') then
			l = HIGH
		elseif x == params:get('pattern_quant') then
			l = MED
		elseif x < params:get('pattern_quant') then
			l = LOW
		end
		g:led(x,2,l)
	end

	for x=1,16 do -- duration
		local l = OFF
		if x == params:get('ms_duration_pos') then
			l = HIGH
		elseif x == params:get('ms_duration_'..params:get('ms_cursor')) then
			l = MED
		elseif x < params:get('ms_duration_'..params:get('ms_cursor')) then
			l = LOW
		end
		g:led(x,7,l)
	end

	for x=1,16 do
		for y=1,4 do
			local n = x+((y-1)*16)
			local l = OFF
			local oob = not ((n>=params:get('ms_first')) and (n<=params:get('ms_last')))
			if n == params:get('ms_cursor') then
				l = HIGH
			elseif n == params:get('ms_pos') then
				-- l = params:get('playing') == 1 and wavery_light or MED 
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
		if x == params:get('active_pattern') then
			l = HIGH
		elseif x == params:get('cued_pattern') then
			l = wavery_light
		else
			l = LOW
		end
		g:led(x,1,l)
	end

	for x=1,16 do -- cue clock
		local l = OFF
		if x == params:get('pattern_quant_pos') then
			l = HIGH
		elseif x == params:get('pattern_quant') then
			l = MED
		elseif x < params:get('pattern_quant') then
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
				if data:get_page_val(at(),'retrig','pos') == x and params:get('playing') == 1 then
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
				if params:get('mod') == 2 and not out_of_bounds(at(),'retrig',x) then
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
		if x == data:get_page_val(at(),'note','pos') and params:get('playing') == 1 then 
			l = LOW
		else
			l = OFF
		end
		for y=1,7 do
			local ly = l
			if y == d then
				ly = out_of_bounds(at(),'note',x) and LOW or HIGH
				if params:get('note_sync') == 1 and data:get_step_val(at(),'trig',x) == 0 then
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
		if x == data:get_page_val(at(),'transpose','pos') and params:get('playing') == 1 then 
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
			if x == data:get_page_val(at(),'octave','pos') and params:get('playing') == 1 then
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
			if x == data:get_page_val(at(),'slide','pos') and params:get('playing') == 1 then
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
			if x == data:get_page_val(at(),'gate','pos') and params:get('playing') == 1 then
				l = highlight(l)
			end
			g:led(x,1+y,l)
		end
	end
end

return Graphics