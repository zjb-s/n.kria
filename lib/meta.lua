Meta = {}

function Meta:reset()
	for t=1,NUM_TRACKS do
		for k,v in ipairs(combined_page_list) do
			if v == 'scale' or v == 'patterns' then break end
			params:set('pos_'..v..'_t'..t, params:get('loop_last_'..v..'_t'..t))
		end
	end
	pulse_indicator = 1
	post('reset')
end

return Meta