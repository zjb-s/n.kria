-- n.Kria                        :-)
-- v0.22 @zbs @sixolet
--
-- native norns kria
-- original design by @tehn
--
--     \/ controls below \/
-- [[-----------------------------]]
-- k1: shift key
-- k2: reset all tracks
-- k1+k2: time config (legacy)
-- k3: play/stop
-- k1+k3: options (legacy)
--
-- e1: bpm
-- e1+k1: swing
-- e2: stretch
-- e3: push
--
-- hold a track/page and...
-- - k2: copy
-- - k3: paste
-- - k2+k3: cut
-- [[-----------------------------]]


--[[
WHAT GOES IN THIS FILE:
- includes
- all coroutines
- basic functions

]]--

globals = include('lib/globals')
screen_graphics = include('lib/screen_graphics')
grid_graphics = include('lib/grid_graphics')
Prms = include('lib/prms')
Onboard = include('lib/onboard')
gkeys = include('lib/gkeys')
meta = include('lib/meta')
data = include('lib/data_functions')
transport = include('lib/transport')
hs = include('lib/dualdelay')
nb = include("lib/nb/lib/nb")
mu = require 'musicutil'

-- hardware
g = grid.connect()
m = midi.connect()

-- matrix
matrix_status, matrix = pcall(require, 'matrix/lib/matrix')
if not matrix_status then matrix = nil end

-- mods
local toolkit_status = util.file_exists('/home/we/dust/code/toolkit')

function init()
	globals:add()
	nb.voice_count = 4
	nb:init()
	Prms:add()
	hs.init()

	data.pattern = ap()

	track_clipboard = meta:get_track_copy(0)
	page_clipboards = meta:get_track_copy(0)

	add_modulation_sources()
	init_kbuf()
	init_value_buffer()

	visual_metro = metro.init(update_visuals,1/15,-1)
	visual_metro:start()
	grid_metro = metro.init(update_grid,1/60,-1)
	grid_metro:start()

	coros.step_ticker = clock.run(step_ticker)
	coros.intro = clock.run(intro)

	last_touched_track = at()
	last_touched_page = get_page_name()

	print('n.kria launched successfully')
end


-- basic functions
function update_grid()
	grid_graphics:render()
end
function update_visuals() 
	redraw()
end

function init_value_buffer()
	for t=1,NUM_TRACKS do
		table.insert(value_buffer,{})
		for k,v in pairs(pages_with_steps) do
			--print('adding',v,'to value buffer')
			value_buffer[t][v] = 0
		end
	end
end

function init_kbuf()
	for x=1,16 do
		table.insert(kbuf,{})
		for y=1,8 do kbuf[x][y] = false end
	end
end

function intro()
	post('n.Kria', true)
	clock.sleep(0.1)
	params:bang()
	clock.sleep(2)
	post('by @zbs', true)
	clock.sleep(2)
	post('based on kria by @tehn', true)
	clock.sleep(2)
	post('see splash for controls', true)
end

function pattern_longpress_clock(x)
	clock.sleep(0.5)
	if kbuf[x][1] then
		meta:save_pattern_into_slot(x)
		just_saved_pattern = true
	end
end

function menu_clock(n)
	blink.menu[n] = true
	clock.sleep(1/4)
	blink.menu[n] = false
end

function key(n,d) Onboard:key(n,d) end
function enc(n,d) Onboard:enc(n,d) end
function g.key(x,y,z) gkeys:key(x,y,z) end

function clock.transport.start() data:set_global_val('playing',1); post('play') end
function clock.transport.stop() data:global_set_val('playing',0); post('stop') end

function post(str,intro) 
	-- second arg: send true if we shouldn't interrupt the intro sequence.
	-- basically don't worry about it
	post_buffer = str 
	if (not intro) and (coros.intro) then
		clock.cancel(coros.intro)
	end
end

function add_modulation_sources()
	if matrix == nil then return end
	for i=1,NUM_TRACKS do
		matrix:add_bipolar("pitch_t"..i, "track "..i.." final cv")
		for _,v in ipairs(matrix_sources) do
			matrix:add_unipolar(v..'_t'..i, 'track '..i..' '..v)
		end
		
		matrix:add_binary('trig_t'..i, 'track '..i..' trig')
		table.insert(trig_sources,'trig_t'..i)
	end

	if toolkit_status then
		for i=1,4 do
			table.insert(trig_sources,'rhythm_'..i)
		end
	end
end

function note_clock(track)
	local player = data:get_player(track)
	local slide_or_modulate = current_val(track,'slide') -- to match stock kria times
	local velocity = current_val(track,'velocity')
	local divider = data:get_page_val(track,'trig','divisor')
	local subdivision = current_val(track,'retrig')
	local gate_len = current_val(track,'gate')
	local gate_multiplier = data:get_track_val(track,'gate_shift')
	local duration = util.clamp(gate_len-1, 0, 4)/16
	if gate_len == 1 or gate_len == 6 then
		duration = duration + 0.02 -- this turns the longest notes into ties, and the shortest into blips, at mult of 1
	else
		duration = duration - 0.02
	end
	duration = duration * gate_multiplier
	-- print('repeating note '..subdivision..' times')
	for i=1,subdivision do
		if data:get_subtrig(track,data:get_pos(track,'retrig'),i)==1 then
			if data:get_track_val(track,'trigger_clock') == 1 then
				for _,v in pairs(trigger_clock_pages) do transport:advance_page(track,v) end
			end
			local description = player:describe()
			meta:update_last_notes()
			local note = description.style == 'kit' and last_notes_raw[track] or last_notes[track]
			player:play_note(note, (velocity-1)/6, duration/subdivision)
			
			if matrix ~= nil then 
				matrix:set("pitch_t"..track, (note - 36)/(127-36))
				matrix:set('trig_t'..track,1)
				matrix:set('trig_t'..track,0)
			end

			local note_str
			if description.style == 'kit' then
				note_str = ''
				for x=0,note,3 do
					note_str = ' ' .. note_str
				end

				note_str = note_str..note
			else
				note_str = mu.note_num_to_name(note, true)
			end
			if description.supports_slew then
				local slide_amt = util.linlin(1,7,1,120,slide_or_modulate) -- to match stock kria times
				player:set_slew(slide_amt/1000)
			else
				local num = util.linlin(1,7,0,1,slide_or_modulate)
				player:modulate(num)
			end
			screen_graphics:add_history(track, note_str, clock.get_beats())
		end
		clock.sleep(clock.get_beat_sec()*divider/(4*subdivision))
	end
end

function step_ticker()
	while true do
		clock.sync(1/4)
		if data:get_global_val('swing_this_step') == 1 then
			data:set_global_val('swing_this_step',0)
			local amt = (clock.get_beat_sec()/4)*((data:get_global_val('swing')-50)/100)
			clock.sleep(amt)
		else
			data:set_global_val('swing_this_step',1)
		end
		if data:get_global_val('playing') == 1 then
			transport:advance_all()
		end
	end
end

function redraw() screen_graphics:render() end 

function at() -- get active track
	return data:get_global_val('active_track')
end

function set_active_track(n)
	data:set_global_val('active_track',n)
	post('track ' .. n)
end

function ap() -- get active pattern
	return data:get_global_val('active_pattern')
end

-- function track_available(t)
-- 	local max = get_script_mode() == 'extended' and 7 or 4
-- 	return t <= max
-- end

local function real_out_of_bounds(track,p,value)
	-- returns true if value is out of bounds on page p, track —— for real not just temporary.
	return 	(value < data:get_page_val(track,p,'loop_first'))
	or 		(value > data:get_page_val(track,p,'loop_last'))
end

function out_of_bounds(track,p,value, real)
	-- returns true if value is out of bounds on page p, track
	if real then
		return real_out_of_bounds(track, p, value)
	end
	return 	(value < data:get_loop_first(track,p))
	or 		(value > data:get_loop_last(track,p))
end

function get_page_name(page,alt)
	local r
	local page = page and page or data:get_global_val('page')
	local alt = alt and alt or (data:get_global_val('alt_page') == 1)
	r = alt and alt_page_names[page] or page_names[page]
	return r
end

function get_display_page_name()
	local p = get_page_name()
	if p == "slide" then
		local description = data:get_player(at()):describe()
		if not description.supports_slew then
			p = description.modulate_description
		end
	end
	return p
end

function current_val(track,page)
	return value_buffer[track][page]
end

function get_mod_key()
	return mod_names[data:get_global_val('mod')]
end

function get_overlay()
	return overlay_names[data:get_global_val('overlay')]
end

function get_script_mode()
	return params:string('script_mode')
end

function set_overlay(name)
	local num = tab.key(overlay_names,name)
	num = util.clamp(num,1,get_script_mode()=='extended' and 4 or 3)
	data:set_global_val('overlay',num)
	post('overlay: '..get_overlay())
end

function track_key_held()
	if kbuf[1][8] or kbuf[2][8] or kbuf[3][8] or kbuf [4][8] then
		return last_touched_track
	else
		return 0
	end
end

function page_key_held()
	if kbuf[6][8] or kbuf[7][8] or kbuf[8][8] or kbuf[9][8] then
		return last_touched_page
	else
		return 0
	end
end

function highlight(l)
	return util.clamp(l+2,0,15)
end

function dim(l) -- level number
	local o
	if l == LOW then
		o = 1
	elseif l == MED then
		o = 3
	elseif l == HIGH then
		o = 9
	else
		o = l - 1
	end

	return util.clamp(o,0,15)
end
