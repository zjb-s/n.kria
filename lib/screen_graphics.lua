--[[
WHAT GOES IN THIS FILE:
- everything related to how the screen looks
]]--

Graphics = {
	history = {} -- keys are unique. values are like {track: 1, note: "A", beats: 234}
}

function Graphics:render()
	s = screen
	s.clear()
	
	self:post()
	self:note_history()
	self:right_windows()
	self:scale()

	if get_overlay() == 'time' then
		self:description_window()
		self:time_descriptions()
	elseif get_overlay() == 'options' then
		self:description_window()
		self:config_descriptions()
	end

	s.update()
end

function Graphics:track_options()

	for k,v in ipairs(track_options) do
		local l = data:get_track_val(at(),v) == 1 and HIGH or LOW
		local x = (track_options_xes[k]==1) and 86 or 78
		local y = ((k-1)*7)+2 
		
		s.level(l)
		s.move(s.text_extents(string.upper(v))+5,y+3)
		s.line_width(2)
		s.line(x,y+3)
		s.stroke()
		
		s.line_width(1)
		s.rect(x,y,6,6)
		s.fill()

		s.level(MED)
		s.move(2,y+5)
		s.text(string.upper(v))

	end
	s.level(LOW)
	s.text_rotate(120,2,'OVERRIDES',90)
	s.text_rotate(112,2,'GLOBAL',90)
	s.text_rotate(104,2,'SETTINGS',90)
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
		s.text(mu.note_num_to_name(meta:make_scale()[(8-i)+data:get_global_val('root_note')]))
	end
end

function Graphics:config_descriptions()
	
	local line_1,line_2;
	if get_script_mode() == 'classic' then
		line_1 = config_desc[1][data:get_global_val('note_sync') + 1]
		line_2 = config_desc[2][data:get_global_val('loop_sync')]
	elseif get_script_mode() == 'extended' then
		line_1 = 'n.kria is in extended mode'
		line_2 = 'use time mod page instead'
	end

	s.move(64,40)
	s.level(OFF)
	s.text_center(string.upper(line_1))
	s.move(64,48)
	s.text_center(string.upper(line_2))

end

function Graphics:time_descriptions()
	local rune_1 = data:get_global_val('note_div_sync')
	local rune_3 = data:get_global_val('div_sync')

	if get_script_mode() == 'classic' then
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
	elseif get_script_mode() == 'extended' then
		s.level(OFF)
		s.move(64,40)
		s.text_center('N.KRIA IS IN EXTENDED MODE')
		s.move(64,48)
		s.text_center('USE TIME MOD PAGE INSTEAD')
	end

end

function Graphics:right_windows()
	local left_border = 92
	local height = 10
	local names = {
		'BPM'
	,	'SWING'
	,	'STRETCH'
	,	'PUSH'
	}

	for k,v in ipairs(names) do
		if get_script_mode() == 'classic' and k>2 then break end
		s.level(blink.menu[k] and MED or LOW)
		s.rect(left_border,(height*k)+1,128-left_border,-height)
		s.fill()

		s.level(blink.menu[k] and OFF or MED)
		s.move(125,(height*k)-2)
		if v == 'BPM' then 
			str = blink.menu[k] and util.round(params:get('clock_tempo')) or 'BPM'
		elseif v == 'SWING' then
			str = blink.menu[k] and data:get_global_val('swing')..'%' or 'SWING'
		elseif v == 'STRETCH' then
			str = blink.menu[k] and data:get_global_val('stretch') or 'STRETCH'
		elseif v == 'PUSH' then
			str = blink.menu[k] and data:get_global_val('push') or 'PUSH'
		end
		s.text_right(str)
	end

	s.level(MED)
	local h =height*#names
	if get_script_mode() == 'classic' then h = h / 2 end
	s.rect(left_border,1,128-left_border,h)
	s.stroke()
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