Graphics = {}

function buf(x,y,v) rbuf[x][y] = v end

function Graphics:trig()
	local l = OFF;
	for t=1,NUM_TRACKS do
		for x=1,16 do
			l = OFF
			local this_trig_on = params:get('data_trig_'..x..'_t'..t) == 1
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

			if x == params:get('pos_trig_t'..t) and params:get('playing') == 1 then
				l = highlight(l)
			end
			if get_mod_key() == 'loop' and not oob then
				l = highlight(l)
			end
			buf(x,t,l)
		end
	end
end

function Graphics:render()

	-- \/\/ these are in order of precedence \/\/
	local p = get_page_name()
	if params:get('overlay') == 2 then
		self:config_1()
	elseif params:get('overlay') == 3 then
		self:config_2()
	elseif params:get('mod') == 3 then
		self:time()
	elseif params:get('mod') == 4 then
		self:prob()
	elseif p == 'trig' then self:trig()
	elseif p == 'retrig' then self:retrig()
	elseif p == 'note' then self:note()
	elseif p == 'transpose' then self:transpose()
	elseif p == 'octave' then self:octave()
	elseif p == 'slide' then self:slide()
	elseif p == 'gate' then self:gate()
	elseif p == 'scale' then self:scale()
	elseif p == 'pattern' then self:pattern()
	end

	if params:get('overlay') == 1 then 
		self:tracks()
		self:pages()
		self:modifiers()
	end

	self:buffer_to_hardware()
end

function Graphics:buffer_to_hardware()
	g:all(OFF)
	for x=1,16 do
		for y=1,8 do
			local v = rbuf[x][y]
			if v ~= 0 then
				g:led(x,y,rbuf[x][y])
				rbuf[x][y] = OFF
			end
		end
	end
	g:refresh()
end

function Graphics:config_1()
	local l
	-- note div sync
	l = params:get('note_div_sync') == 1 and HIGH or MED
	for i=1,4 do buf(i,5,l) end
	buf(1,6,l);buf(4,6,l);buf(1,7,l);buf(4,7,l)
	for i=1,4 do buf(i,8,l) end

	-- div cue
	l = params:get('div_cue') == 1 and HIGH or MED
	buf(8,7,l);buf(9,7,l);buf(8,8,l);buf(9,8,l)

	-- div sync
	l = params:get('div_sync') == 2 and HIGH or MED
	buf(13,6,l)
	l = params:get('div_sync') == 3 and HIGH or MED
	for i=1,4 do
		buf(12+i,8,l)
	end

	-- timing inc/dec keysets
	buf(7,5,HIGH)
	buf(8,5,MED)
	buf(9,5,MED)
	buf(10,5,HIGH)

	-- arrows
	if kbuf[7][5] then 
		buf(7,4,HIGH)
		buf(6,5,HIGH)
		buf(7,6,HIGH)
	end
	if kbuf[8][5] then
		buf(8,4,MED)
		buf(8,6,MED)
	end
	if kbuf[9][5] then
		buf(9,4,MED)
		buf(9,6,MED)
	end
	if kbuf[10][5] then
		buf(10,4,HIGH)
		buf(11,5,HIGH)
		buf(10,6,HIGH)
	end

	self:time(params:get('global_clock_div'))

end

function Graphics:config_2()
	-- note sync
	l = params:get('note_sync') == 1 and HIGH or MED
	for i=1,4 do buf(i+2,3,l) end
	buf(3,4,l);buf(6,4,l);buf(3,5,l);buf(6,5,l)
	for i=1,4 do buf(i+2,6,l) end

	-- loop sync
	l = params:get('loop_sync') == 2 and HIGH or MED
	buf(11,4,l)
	l = params:get('loop_sync') == 3 and HIGH or MED
	for i=1,4 do
		buf(10+i,6,l)
	end



end

function Graphics:tracks()
	local l
	for i=1,NUM_TRACKS do
		l = i == at() and HIGH or MED
		if params:get('mute_t'..i) == 1 then
			l = util.round(l/4)
		end
		buf(i,8,l)
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
		buf(x,8,l) -- bottom row
	end
end

function Graphics:modifiers()
	local l;
	for i=1,3 do
		l = params:get('mod')-1 == i and HIGH or LOW
		buf(10+i,8,l)
	end
end

function Graphics:time(D)
	local l
	local d = D or params:get('divisor_'..get_page_name()..'_t'..at())
	local amount = util.round(HIGH/d)
	for x=1,16 do
		if x > d then 
			l = LOW
		elseif x == d then
			l = HIGH
		else
			l = amount*x
		end
		buf(x,2,l)
	end
end

function Graphics:prob()
	local d
	for x=1,16 do
		d = params:get('data_'..get_page_name()..'_prob_'..x..'_t'..at())
		buf(x,6,LOW)
		buf(x,7-d,HIGH)
	end
end

function Graphics:scale()
	for i=1,16 do -- scale select
		local y = (i > 8) and 7 or 6
		local l = (params:get('scale_num') == i) and HIGH or MED
		buf(((i-1) % 8)+1, y, l)
	end

	for t=1,4 do -- play modes
		buf(1,t,LOW)
		buf(7,t,LOW)
		for x=1,5 do
			local l = params:get('playmode_t'..t) == x and HIGH or MED
			buf(x+1,t,l)
		end
	end

	for i=1,7 do -- scale editor
		buf(9,8-i,LOW)
		local d = params:get('scale_'..params:get('scale_num')..'_deg_'..i)
		buf(9+d,8-i,HIGH)

	end
end

function Graphics:pattern()
	-- todo
end

function Graphics:retrig()
	for x=1,16 do
		local d = params:get('data_retrig_'..x..'_t'..at())
		local l = HIGH
		if d >= 0 and d <= 6 then
			for i=(7-d),7 do
				buf(x,i,l)
				l = l - 2
			end
		end

		if params:get('pos_retrig_t'..at()) == x and params:get('playing') == 1 then
			l = MED
		else
			l = LOW
		end

		if params:get('mod') == 2 and not out_of_bounds(at(),'retrig',x) then
			l = highlight(l)
		end
		buf(x,7,l)
	end
end

function Graphics:note()
	local l
	for x=1,16 do
		local d = params:get('data_note_'..x..'_t'..at())
		if x == params:get('pos_note_t'..at()) and params:get('playing') == 1 then 
			l = LOW
		else
			l = OFF
		end
		for y=1,7 do
			local ly = l
			if y == d then
				ly = out_of_bounds(at(),'note',x) and LOW or HIGH
			end
			if get_mod_key() == 'loop' and not out_of_bounds(at(),'note',x) then
				ly = highlight(ly)
			end
			buf(x,8-y,ly)
		end
	end
end

function Graphics:transpose() -- identical to above, might want to fold them together
	local l
	for x=1,16 do
		local d = params:get('data_transpose_'..x..'_t'..at())
		if x == params:get('pos_transpose_t'..at()) and params:get('playing') == 1 then 
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
			buf(x,8-y,ly)
		end
	end
end

function Graphics:octave()
	local d = params:get('data_octave_shift_t'..at()) 
	-- todo implement octave shift
	for i=1,5 do
		buf(i,1,(params:get('data_octave_shift_t'..at())==i and MED or LOW))
	end
	for x=1,16 do
		d = params:get('data_octave_'..x..'_t'..at())
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
			if x == params:get('pos_octave_t'..at()) and params:get('playing') == 1 then
				l = highlight(l)
			end
			buf(x,8-i,l)
		end
	end
end

function Graphics:slide()
	for x=1,16 do
		local l = OFF
		local d = params:get('data_slide_'..x..'_t'..at())
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
			if x == params:get('pos_slide_t'..at()) and params:get('playing') == 1 then
				l = highlight(l)
			end
			buf(x,8-y,l)
		end
	end
end

function Graphics:gate()
	local s = params:get('data_gate_shift_t'..at())
	for i=1,s do
		local l = LOW
		if i == s then
			l = HIGH
		elseif i > s then
			l = OFF
		end
		buf(i,1,l)
	end

	for x=1,16 do
		local l = OFF
		local d = params:get('data_gate_'..x..'_t'..at())
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
			if x == params:get('pos_gate_t'..at()) and params:get('playing') == 1 then
				l = highlight(l)
			end
			buf(x,1+y,l)
		end
	end
end

return Graphics