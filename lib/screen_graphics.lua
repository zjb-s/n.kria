Graphics = {
	history = {} -- keys are unique. values are like {track: 1, note: "A", beats: 234}
}

function Graphics:render()
	s = screen
	s.clear()
	
	self:note_history()
	self:post()
	self:right_windows()
	self:scale()
	-- self:notes()

	if params:get('overlay') == 2 then
		self:description_window()
		self:time_descriptions()
	elseif params:get('overlay') == 3 then
		self:description_window()
		self:config_descriptions()
	end

	s.update()
end

function Graphics:add_history(track, note, beats)
	local key = note..track..beats
	self.history[key] = {
		note=note,
		track=track,
		beats=beats,
	}
end

function Graphics:note_history()
	local now = clock.get_beats()
	s.aa(1)
	for k, hist in pairs(self.history) do
		local ago = (now - hist.beats)
		if ago > 5 then
			self.history[k] = nil
		else
			s.level(HIGH)
			s.move((hist.track*19)-1, 54 - (54/4.0)*ago)
			s.text(hist.note)
		end
	end
	s.aa(0)
end

function Graphics:scale()
	s.level(MED)
	s.rect(0,0,14,53)
	s.fill()
	s.level(LOW)
	s.rect(1,1,13,52)
	s.stroke()

	s.level(1)
	for i=1,7 do
		s.move(2,7*i+1)
		s.text(mu.note_num_to_name(make_scale()[(8-i)+params:get('root_note')]))
	end
end

function Graphics:config_descriptions()
	local line_1 = config_desc[1][params:get('note_sync') + 1]
	local line_2 = config_desc[2][params:get('loop_sync')]

	s.move(64,40)
	s.level(OFF)
	s.text_center(string.upper(line_1))
	s.move(64,48)
	s.text_center(string.upper(line_2))

end

function Graphics:time_descriptions()
	local rune_1 = params:get('note_div_sync')
	local rune_3 = params:get('div_sync')

	if 		(rune_1 == 0) and (rune_3 == 1) then desc_num = 1
		elseif	(rune_1 == 1) and (rune_3 == 1) then desc_num = 2
		elseif 	(rune_1 == 0) and (rune_3 == 2) then desc_num = 3
		elseif 	(rune_1 == 1) and (rune_3 == 2) then desc_num = 4
		elseif 	(rune_1 == 0) and (rune_3 == 3) then desc_num = 5
		elseif 	(rune_1 == 1) and (rune_3 == 3) then desc_num = 6
	end

	desc = time_desc[desc_num]
	s.move(64,40)
	s.level(OFF)
	s.text_center(string.upper(desc[1]))
	if tab.count(desc) > 1 then
		s.move(64,48)
		s.text_center(string.upper(desc[2]))
	end
end

function Graphics:right_windows()
	local x = 110
	local y = 11
	local w = 36
	local h = 10

	-- bpm window
	s.level(MED)
	s.rect(x-(w/2),11,w,-h)
	s.fill()
	s.level(blink.e1 and HIGH or LOW)
	s.rect(x-(w/2),21,w,-h)
	s.fill()
	s.level(LOW)
	s.rect(x-(w/2),21,w,-h*2)
	s.stroke()

	-- bpm text
	s.level(OFF)
	s.move(x-1,9)
	s.text_center(shift and 'SWING' or 'BPM')
	s.level(blink.e1 and LOW or MED)
	s.move(x-1,18)
	if shift then
		s.text_center(params:get('swing')..'%')
	else
		s.text_center(util.round(params:get('clock_tempo')))
	end

	-- page window
	s.level(MED)
	s.rect(x-(w/2),33,w,-h)
	s.fill()
	s.level(LOW)
	s.rect(x-(w/2),43,w,-h)
	s.fill()
	s.level(LOW)
	s.rect(x-(w/2),43,w,-h*2)
	s.stroke()
	s.level(OFF)
	s.move(x-1,31)

	-- page text
	s.text_center(string.upper(get_page_name_short()))

	s.level(MED)
	s.move(x-1,41)
	if get_page_name() == 'pattern' then
		s.text_center(division_names[params:get('pattern_quant')])
	elseif get_page_name() == 'scale' then
		s.text_center('-')
	else
		s.text_center(division_names[data:get_page_val(at(),get_page_name(),'divisor')])
	end



end

function Graphics:description_window()
	s.level(HIGH)
	s.rect(0,52,128,-20)
	s.fill()
	s.level(LOW)
	s.rect(1,53,127,-21)
	s.stroke()
end

function Graphics:post()
	s.level(HIGH)
	s.rect(0,64,128,-10)
	s.fill()
	s.move(1,62)
	s.level(0)
	s.text('\u{0bb}')
	s.move(8,62)
	s.text(string.upper(post_buffer))
end

return Graphics