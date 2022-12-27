Graphics = {}

function Graphics:render()
	s = screen
	s.clear()
	
	self:post()
	self:bpm_window()
	self:scale()
	self:notes()

	if params:get('overlay') == 2 then
		self:description_window()
		self:time_descriptions()
	elseif params:get('overlay') == 3 then
		self:description_window()
		self:config_descriptions()
	end

	s.update()
end

function Graphics:scale()
	s.level(LOW)
	s.rect(0,52,128,-9)
	s.fill()

	s.level(MED)
	for i=1,7 do
		s.move(4+((i-1)*18),50)
		s.text(mu.note_num_to_name(make_scale()[i]))
	end
end

function Graphics:notes()
	--todo
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

function Graphics:bpm_window()
	s.line_width(1)
	s.level(HIGH)
	s.rect(1,3,31,25)
	s.fill()
	s.level(LOW)
	s.rect(1,3,31,26)
	s.stroke()
	s.rect(1,16,31,12)
	s.fill()

	s.level(OFF)
	s.move(15,12)
	s.text_center('BPM')
	s.level(HIGH)
	s.move(15,25)
	s.text_center(util.round(params:get('clock_tempo')))

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