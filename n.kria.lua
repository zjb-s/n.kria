-- n.Kria                        :-)
-- v0.19 @zbs
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
- global variable declarations
- all coroutines
- some basic utilities like ap() or at()

NOTES ABOUT SCRIPT STRUCTURE:
- each file has a summary of its contents at the top
- i think everything else is fairly self-explanatory right now
]]--

hs = include('lib/dualdelay')
screen_graphics = include('lib/screen_graphics')
grid_graphics = include('lib/grid_graphics')
Prms = include('lib/prms')
Onboard = include('lib/onboard')
gkeys = include('lib/gkeys')
meta = include('lib/meta')
data = include('lib/data_functions')
transport = include('lib/transport')
nb = include("lib/nb/lib/nb")
mu = require 'musicutil'

-- matrix
local status, matrix = pcall(require, 'matrix/lib/matrix')
if not status then matrix = nil end

-- macros
OFF=0
LOW=2
MED=5
HIGH=12
NUM_TRACKS = 4
NUM_PATTERNS = 16
NUM_SCALES = 16

-- global tables
division_names = {
	'1/16'
,	'1/8'
,	'1/8.'
,	'1/4'
,	'5/16'
,	'1/4.'
,	'7/16'
,	'1/2'
,	'9/16'
,	'5/8'
,	'11/16'
,	'1/2.'
,	'13/16'
,	'7/8'
,	'15/16'
,	'1/1'
}
scale_defaults = {
	{0,2,2,1,2,2,2}
,	{0,2,1,2,2,2,1}
,	{0,1,2,2,2,1,2}
,	{0,2,2,2,1,2,2}
,	{0,2,2,1,2,2,1}
,	{0,2,1,2,2,1,2}
,	{0,1,2,2,1,2,2}
,	{0,0,1,0,1,1,1}
,	{0,0,0,0,0,0,0}
,	{0,0,0,0,0,0,0}
,	{0,0,0,0,0,0,0}
,	{0,0,0,0,0,0,0}
,	{0,0,0,0,0,0,0}
,	{0,0,0,0,0,0,0}
,	{0,0,0,0,0,0,0}
,	{0,0,0,0,0,0,0}
}
page_defaults = {
	trig = {min=0,max=1,default=0} 
,	note = {min=1,max=7,default=1} 
,	octave = {min=1,max=7,default=3} 
,	gate = {min=1,max=7,default=1} 
,	retrig = {min=0,max=5,default=1} 
,	transpose = {min=1,max=7,default=1} 
,	slide = {min=1,max=7,default=1} 
}
page_map = { -- x coordinate map for grid key presses
	[6] = 1
,	[7] = 2
,	[8] = 3
,	[9] = 4
,	[15] = 5
,	[16] = 6
}
time_desc = {
	{	
		'all divs independent'
	},{
		'most divs independent'
	,	'trig & note divs synced'
	},{
		'divs synced in track'
	,	'but tracks independent'
	},{
		'trig & note divs synced'
	,	'other divs synced separate'
	},{
		'all divs synced'
	},{		
		'most divs globally synced'
	,	'trig & note synced separate'
	}
}
config_desc = {
	{
		'note & trig edits free'
	,	'trig & note edits synced'
	},{
		'all loops independent'
	,	'loops synced inside tracks'
	,	'all loops synced'
	}
}

-- more global tables
page_names = {'trig', 'note', 'octave', 'gate','scale','pattern'}
alt_page_names = {'retrig', 'transpose', 'slide'}
combined_page_list = {'trig','note','octave','gate','retrig','transpose','slide','scale','pattern'}
pages_with_steps = {'trig','retrig','note','transpose','octave','slide','gate'}
trigger_clock_pages = {'note','transpose','octave','slide','gate'}
mod_names = {'none','loop','time','prob'}
play_modes = {'forward', 'reverse', 'triangle', 'drunk', 'random'}
prob_map = {0, 25, 50, 100}
div_sync_modes = {'none','track','all'}
overlay_names = {'none','time','options','copy/paste'}
blink = {
-- 	e1 = false
-- ,	e2 = false
-- ,	e3 = false
	menu = {false,false,false,false,false}
}

coros = {}
value_buffer = {}
page_clipboards = {}
track_clipboard = {}
pattern_clipboard = {}
ms_step_clipboard = {}
last_notes = {0,0,0,0}
temp_scale = {-1,-1,-1,-1,-1,-1}

post_buffer = 'n.kria'
loop_first = -1
loop_last = -1
wavery_light = MED
waver_dir = 1
last_touched_page = 'trig'
last_touched_track = 1
last_touched_ms_step = 1
pulse_indicator = 1
global_clock_counter = 1
just_pressed_clipboard_key = false

g = grid.connect()

-- buffers
kbuf = {} -- key state buffer, true/false
onboard_key_states = {false,false,false}

-- basic functions
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
	post('n.Kria')
	clock.sleep(0.1)
	params:bang()
	clock.sleep(2)
	post('by @zbs')
	clock.sleep(2)
	post('based on kria by @tehn')
	clock.sleep(2)
	post('see splash for controls')
end

function menu_clock(n)
	blink.menu[n] = true
	clock.sleep(1/4)
	blink.menu[n] = false
end

function key(n,d) Onboard:key(n,d) end
function enc(n,d) Onboard:enc(n,d) end
function g.key(x,y,z) gkeys:key(x,y,z) end

function clock.transport.start() params:set('playing',1); post('play') end
function clock.transport.stop() params:set('playing',0); post('stop') end

function post(str) post_buffer = str end

function init()
	hs.init()
	nb.voice_count = 4
	nb:init()
	Prms:add()
	track_clipboard = meta:get_track_copy(0)
	page_clipboards = meta:get_track_copy(0)
	add_modulation_sources()
	init_kbuf()
	init_value_buffer()
	coros.visual_ticker = clock.run(visual_ticker)
	coros.step_ticker = clock.run(step_ticker)
	coros.intro = clock.run(intro)
	last_touched_track = at()
	last_touched_page = get_page_name()
	print('n.kria launched successfully')
end

function add_modulation_sources()
	if matrix == nil then return end
	for i=1,NUM_TRACKS do
		-- The final pitch
		matrix:add_bipolar("pitch_t"..i, "track "..i.." cv")
		-- The raw note, unaffected by transpose or anything
		matrix:add_unipolar("note_t"..i, "track "..i.." note")
	end
end

function note_clock(track)
	local player = params:lookup_param("voice_t"..track):get_player()
	local slide_or_modulate = current_val(track,'slide') -- to match stock kria times
	local velocity = 1.0
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
		if data:get_subtrig(track,data:get_page_val(track,'retrig','pos'),i)==1 then
			if data:get_track_val(track,'trigger_clock') == 1 then
				for _,v in pairs(trigger_clock_pages) do transport:advance_page(track,v) end
			end
			meta:update_last_notes()
			local note = last_notes[track]
			player:play_note(note, velocity, duration/subdivision)

			if matrix ~= nil then matrix:set("pitch_t"..track, (note - 36)/(127-36)) end
			local note_str = mu.note_num_to_name(note, true)
			local description = player:describe()
			if description.supports_slew then
				local slide_amt = util.linlin(1,7,1,120,slide_or_modulate) -- to match stock kria times
				player:set_slew(slide_amt/1000)
			else
				player:modulate(util.linlin(1,7,0,1,slide_or_modulate))
			end
			screen_graphics:add_history(track, note_str, clock.get_beats())
		end
		clock.sleep(clock.get_beat_sec()*divider/(4*subdivision))
	end
end

function step_ticker()
	while true do
		data.pattern = ap()
		clock.sync(1/4)
		if params:get('swing_this_step') == 1 then
			params:set('swing_this_step',0)
			local amt = (clock.get_beat_sec()/4)*((params:get('swing')-50)/100)
			clock.sleep(amt)
		else
			params:set('swing_this_step',1)
		end
		if params:get('playing') == 1 then
			transport:advance_all()
		end
	end
end

function visual_ticker()
	while true do
		clock.sleep(1/30)
		redraw()

		wavery_light = wavery_light + waver_dir
		if wavery_light > MED + 2 then
			waver_dir = -1
		elseif wavery_light < MED - 2 then
			waver_dir = 1
		end
		grid_graphics:render()
	end
end

function redraw()
	screen_graphics:render()
end

function at() -- get active track
	return params:get('active_track')
end

function ap() -- get active pattern
	return params:get('active_pattern')
end

function out_of_bounds(track,p,value)
	-- returns true if value is out of bounds on page p, track
	return 	(value < data:get_page_val(track,p,'loop_first'))
	or 		(value > data:get_page_val(track,p,'loop_last'))
end

function get_page_name(page,alt)
	local page = page and page or params:get('page')
	local alt = alt and alt or (params:get('alt_page') == 1)
	return alt and alt_page_names[page] or page_names[page]
end

function get_display_page_name()
	local p = get_page_name()
	if p == "slide" then
		local description = params:lookup_param("voice_t"..at()):get_player():describe()
		if not description.supports_slew then
			p = description.modulate_description
		end
	end
	return p
end

function current_val(track,page)
	return value_buffer[track][page]
	--return data:get_step_val(track,page,data:get_page_val(track,page,'pos'))
end

function get_mod_key()
	return mod_names[params:get('mod')]
end

function get_overlay()
	return overlay_names[params:get('overlay')]
end

function set_overlay(n)
	params:set('overlay',tab.key(overlay_names,n))
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
