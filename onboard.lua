--[[
WHAT GOES IN THIS FILE:
- everything related to onboard keys and encoders
]]--

local Onboard = {}

function Onboard:enc(n,d)
	if n == 1 then
		if shift then
			if coros.shift_e1 then clock.cancel(coros.shift_e1) end
			coros.shift_e1 = clock.run(menu_clock,2)
			params:delta('swing',d)
			post('swing: ' .. params:get('swing'))
		else
			if coros.e1 then clock.cancel(coros.e1) end
			coros.e1 = clock.run(menu_clock,1)
			params:delta('clock_tempo',d)
			post('tempo: ' .. util.round(params:get('clock_tempo')))
		end
	elseif n == 2 then
		if coros.e2 then clock.cancel(coros.e2) end
		coros.e2 = clock.run(menu_clock,3)
		if shift then
			if d > 0 then
				params:set('stretch',params:get('stretch')<0 and 0 or 64)
			else
				params:set('stretch',params:get('stretch')>0 and 0 or -64)
			end
		else
			params:delta('stretch',d)
		end
		post('stretch: ' .. params:get('stretch'))
	elseif n == 3 then
		if coros.e3 then clock.cancel(coros.e3) end
		coros.e3 = clock.run(menu_clock,4)
		if shift then
			if d > 0 then
				params:set('push',params:get('push')<0 and 0 or 64)
			else
				params:set('push',params:get('push')>0 and 0 or -64)
			end
		else
			params:delta('push',d)
		end
		post('push: '.. params:get('push'))
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