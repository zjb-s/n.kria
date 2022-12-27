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
	s.rect(0,51,128,-9)
	s.fill()

	s.level(MED)
	for i=1,7 do
		s.move(4+((i-1)*18),49)
		s.text(mu.note_num_to_name(make_scale()[i+params:get('root_note')]))
	end
end

function Graphics:notes()
	local track_names = {'one','two','three','four'}
	local x = {1,34,67,100}
	local y = 2
	local window_width = 28
	local window_height = 25
	for t=1,4 do
		s.line_width(1)
		s.level(MED)
		-- todo make this blink high instead of med when a note fires
		s.rect(x[t],y,window_width,window_height)
		s.fill()
		s.level(LOW)
		s.rect(x[t],y,window_width,window_height)
		s.stroke()
		s.rect(x[t],y+window_height/2,window_width,window_height/2)
		s.fill()

		s.move(x[t]+(window_width/2)-1,(window_height/2)-2)
		s.level(OFF)
		s.text_center(string.upper(track_names[t]))

		s.move(x[t]+(window_width/2)-1,(window_height)-2)
		s.level(MED)
		s.text_center(mu.note_num_to_name(data:get_track_val(t,'last_note')))
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

function Graphics:bpm_window()
	s.level(blink.e2 and HIGH or MED)
	s.rect(0,39,64,-9)
	s.fill()
	
	s.level(OFF)
	s.move(14,37)
	s.text_center('BPM')
	s.move(46,37)
	s.text_center(util.round(params:get('clock_tempo')))
	

	s.level(blink.e3 and HIGH or LOW)
	s.rect(64,39,64,-9)
	s.fill()
	s.level(blink.e3 and OFF or MED)
	s.move(80,37)
	s.text_center('SWING')
	s.move(112,37)
	s.text_center(params:get('swing')..'%')

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