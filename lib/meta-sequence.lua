local ms = {}

function ms:key(x,y,z)
	if z == 1 then
		if y == 1 then
			params:set('ms_pattern_'..params:get('ms_cursor'),x)
			post('meta step '..params:get('ms_cursor')..' pattern: '..params:get('ms_pattern_'..params:get('ms_cursor')))
		elseif y > 2 and y < 7 then
			if get_mod_key() == 'loop' then
				--todo
			else
				params:set('ms_cursor',x+((y-3)*16))
				post('meta-sequence cursor: '..params:get('ms_cursor'))
			end
		elseif y == 7 then
			params:set('ms_duration_'..params:get('ms_cursor'),x)
			post('meta step '..params:get('ms_cursor')..' duration: '..params:get('ms_duration_'..params:get('ms_cursor')))
		end
	end
end

return ms