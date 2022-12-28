local Onboard = {}

function Onboard:enc(n,d)
	if n == 1 then
		if e1_clock then clock.cancel(e1_clock) end
		e1_clock = clock.run(touched_enc,1)
		if shift then
			params:delta('swing',d)
			post('swing: ' .. params:get('swing'))
		else
			params:delta('clock_tempo',d)
			post('tempo: ' .. util.round(params:get('clock_tempo')))
		end
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
					if kbuf[1][8] or kbuf[2][8] or kbuf[3][8] or kbuf[4][8] then
						track_clipboard = meta:get_track_copy() 
					else
						meta:reset_all()
					end
				elseif n == 3 then
					if kbuf[1][8] or kbuf[2][8] or kbuf[3][8] or kbuf[4][8] then
						meta:paste_onto_track(last_touched_track,track_clipboard)
					else
						params:delta('playing',1)
						post((params:get('playing') == 1) and 'play' or 'stop')
					end
				end
			end
		end
	end
end

return Onboard