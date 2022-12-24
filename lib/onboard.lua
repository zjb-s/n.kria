local Onboard = {}

function Onboard:enc(n,d)
	if n == 1 then
		params:delta('clock_tempo',d)
	end	
end

function Onboard:key(n,d)

	if n == 1 then 
		shift = d == 1 
		if shift then 
			post('shift...')
		end
	end

	if d == 1 and n ~= 1 then
		if shift then
			if params:get('overlay') == 1 then
				params:set('overlay',n)
				post((params:get('overlay') == 2 and 'timing' or 'config') .. ' overlay')
			else
				params:set('overlay',1)
				post('overview')
			end
		else
			if params:get('overlay') ~= 1 then
				params:set('overlay',1)
				post('overview')
			else
				if n == 2 then
					for t=1,NUM_TRACKS do
						for k,v in ipairs(combined_page_list) do
							if v == 'scale' or v == 'patterns' then break end
							params:set('pos_'..v..'_t'..t, params:get('loop_last_'..v..'_t'..t))
						end
						post('reset')
					end
				elseif n == 3 then
					params:delta('playing',1)
					post((params:get('playing') == 1) and 'play' or 'stop')
				end
			end
		end
	end
end

return Onboard