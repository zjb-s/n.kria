--[[
WHAT GOES IN THIS FILE:
- everything related to onboard keys and encoders
]]--

local Onboard = {}

function Onboard:enc(n,d)
	if n == 1 then
		if onboard_key_states[1] then
			if coros.shift_e1 then clock.cancel(coros.shift_e1) end
			coros.shift_e1 = clock.run(menu_clock,2)
			data:delta_global_val('swing',d)
			post('swing: ' .. data:get_global_val('swing'))
		else
			if coros.e1 then clock.cancel(coros.e1) end
			coros.e1 = clock.run(menu_clock,1)
			params:delta('clock_tempo',d)
			post('tempo: ' .. util.round(params:get('clock_tempo')))
		end
	elseif n == 2 then
		if get_script_mode() == 'extended' then
			if coros.e2 then clock.cancel(coros.e2) end
			coros.e2 = clock.run(menu_clock,3)
			if onboard_key_states[1] then
				if d > 0 then
					data:set_global_val('stretch',data:get_global_val('stretch')<0 and 0 or 64)
				else
					data:set_global_val('stretch',data:get_global_val('stretch')>0 and 0 or -64)
				end
			else
				data:delta_global_val('stretch',d)
			end
			post('stretch: ' .. data:get_global_val('stretch'))
		end
	elseif n == 3 then
		if get_script_mode() == 'extended' then
			if coros.e3 then clock.cancel(coros.e3) end
			coros.e3 = clock.run(menu_clock,4)
			if onboard_key_states[1] then
				if d > 0 then
					data:set_global_val('push',data:get_global_val('push')<0 and 0 or 64)
				else
					data:set_global_val('push',data:get_global_val('push')>0 and 0 or -64)
				end
			else
				data:delta_global_val('push',d)
			end
			post('push: '.. data:get_global_val('push'))
		end
	end
end

function Onboard:key(n,d)
	onboard_key_states[n] = (d==1)
	if d == 1 and n ~= 1 then
		if tab.contains({'options','time'},get_overlay()) then
			set_overlay('none')
		elseif onboard_key_states[2] and onboard_key_states[3] then
			self:both_pressed()
		elseif onboard_key_states[1] then
			set_overlay((n==2) and 'time' or 'options')
		elseif (not onboard_key_states[1]) and (track_key_held()==0 and page_key_held()==0) then
			if n==2 then 
				transport:reset_all()
			elseif n==3 then 
				transport:play_pause()
			end
		elseif (not onboard_key_states[1]) and (track_key_held()~=0) then
			just_pressed_clipboard_key = true
			if n==2 then
				track_clipboard = meta:get_track_copy(last_touched_track)
				post('copied track '..last_touched_track)
			elseif n==3 then
				meta:paste_onto_track(last_touched_track, track_clipboard)
				post('pasted track '..last_touched_track)
			end
		elseif (not onboard_key_states[1]) and (page_key_held()~=0) then
			just_pressed_clipboard_key = true
			local p = get_page_name(last_touched_page)
			if n==2 then
				page_clipboards[p] = meta:get_page_copy(last_touched_track,p)
				post('copied page: t'..at()..' '..p)
			elseif n==3 then
				meta:paste_onto_page(at(),p,page_clipboards[p])
				post('pasted page: t'..at()..' '..p)
			end
		end
	end
end

function Onboard:both_pressed()
	if track_key_held() == 0 and page_key_held() == 0 then
		post('hold track/page to cut')
	else
		if track_key_held() ~= 0 then
			track_clipboard = meta:get_track_copy(last_touched_track)
			meta:paste_onto_track(last_touched_track, meta:get_track_copy(0))
			post('cut track '..last_touched_track)
		elseif page_key_held() ~= 0 then
			local p = get_page_name(last_touched_page)
			page_clipboards[p] = meta:get_page_copy(last_touched_track,p)
			meta:paste_onto_page(at(),p,meta:get_track_copy(0)[p])
			post('cut page: t'..at()..' '..p)
		end
		just_pressed_clipboard_key = true
	end
end

return Onboard