--
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ k2z ~~~~~~~~~~~~~~
-- ~~~~~~~~~ by zbs ~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ kria port native to lua ~~~
-- 0.1 ~~~~~~~~~~~~~~~~~~~~~~~~~
-- 
-- k1: shift
-- k2: reset
-- k3: play
-- shift+k2: time overlay (ansible k1)
-- shift+k3: config overlay (ansible k2)
--
-- e1: tempo
-- e2: nothing
-- e3: nothing
-- shift+e1: swing
--
-- thanks for everything, @tehn

screen_graphics = include('lib/screen_graphics')
grid_graphics = include('lib/grid_graphics')
Prms = include('lib/prms')
Onboard = include('lib/onboard')
gkeys = include('lib/gkeys')
meta = include('lib/meta')
data = include('lib/data_functions')
nb = include("lib/nb/lib/nb")
mu = require 'musicutil'

local status, matrix = pcall(require, 'matrix/lib/matrix')
if not status then matrix = nil end

-- grid level macros
OFF=0
LOW=2
MED=5
HIGH=12

-- other globals
NUM_TRACKS = 4
NUM_PATTERNS = 16
NUM_SCALES = 16

post_buffer = 'k2z v0.1'

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

page_ranges = {
	{0,1,0} -- trig
,	{1,7,1} -- note
,	{1,7,3} -- octave
,	{1,7,1} -- gate
,	{-1,6,1} -- retrig
,	{1,7,1} -- transpose
,	{1,7,1} -- slide
}
page_map = {
	[6] = 1
,	[7] = 2
,	[8] = 3
,	[9] = 4
,	[15] = 5
,	[16] = 6
}
page_names = {'trig', 'note', 'octave', 'gate','scale','pattern'}
alt_page_names = {'retrig', 'transpose', 'slide'}
combined_page_list = {'trig','note','octave','gate','retrig','transpose','slide','scale','pattern'}
mod_names = {'none','loop','time','prob'}
play_modes = {'forward', 'reverse', 'triangle', 'drunk', 'random'}
prob_map = {0, 25, 50, 100}
div_sync_modes = {'none','track','all'}
overlay_names = {'none','time','options','copy/paste'}

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

loop_first = -1
loop_last = -1
wavery_light = MED
waver_dir = 1
shift = false
last_touched_track = 1
last_touched_ms_step = 1
blink = {
	e1 = false
,	e2 = false
,	e3 = false
}
track_clipboard = {}
pattern_clipboard = {}
ms_step_clipboard = {}

pulse_indicator = 1 -- todo implement
global_clock_counter = 1

kbuf = {} -- key state buffer, true/false
rbuf = {} -- render buffer, states 0-15 on all 128 positions

g = grid.connect()
m = midi.connect()

function init_grid_buffers()
	for x=1,16 do
		table.insert(kbuf,{})
		table.insert(rbuf,{})
		for y=1,8 do
			kbuf[x][y] = false -- key buffer
			rbuf[x][y] = OFF -- rendering
		end
	end
end

function post(str)
	post_buffer = str
	-- print('post:',str)
end

function intro()
	clock.sleep(2)
	post('by @zbs')
	clock.sleep(2)
	post('based on kria by @tehn')
	clock.sleep(2)
	post('see splash for controls')
end

function touched_enc(n)
	blink['e'..n] = true
	clock.sleep(1/4)
	blink['e'..n] = false
end

function key(n,d) Onboard:key(n,d) end
function enc(n,d) Onboard:enc(n,d) end
function g.key(x,y,z) gkeys:key(x,y,z) end

function clock.transport.start() params:set('playing',1); post('play') end
function clock.transport.stop() params:set('playing',0); post('stop') end

function init()
	Prms:add()
	track_clipboard = meta:get_track_copy()
	nb:init()
	add_modulation_sources()
	init_grid_buffers()
	clock.run(visual_ticker)
	clock.run(step_ticker)
	clock.run(intro)
end


function add_modulation_sources()
	if matrix == nil then return end
	for i=1,NUM_TRACKS do
		matrix:add_binary("pitch_t"..i, "track "..i.." cv")
	end
end

function make_scale()
	local table_from_params = {}
	for i=1,7 do
		table.insert(table_from_params,params:get('scale_'..params:get('scale_num')..'_deg_'..i))
	end
	local new_scale = {
		[1] = 0
	,	[8] = 12
	}
	params:set('root_note',table_from_params[1])
	for i=2,7 do
		new_scale[i] = new_scale[i-1] + table_from_params[i]
		new_scale[i+7] = new_scale[i] + 12
	end
	-- print('new scale is')
	-- tab.print(new_scale)
	return new_scale
end

function note_clock(track,note,duration,slide_or_modulate)
	local player = params:lookup_param("voice_t"..track):get_player()
	local velocity = 1.0
	local divider = data:get_page_val(track,'trig','divisor')
	local pos = data:get_page_val(track,'retrig','pos')
	local subdivision = data:get_unique(track,'subtrig_count',pos)
	--if track == 1 then print(note) end
	if matrix ~= nil then
		matrix:set("pitch_t"..track, (note - 36)/(127-36))
	end
	local note_str = mu.note_num_to_name(note, true)
	local description = player:describe()
	for i=1,subdivision do
		if params:get('data_subtrig_'..i..'_step_'..pos..'_t'..track..'_p'..ap()) == 1 then
			if description.supports_slew then
				local slide_amt = util.linlin(1,7,1,120,slide_or_modulate) -- to match stock kria times
				player:set_slew(slide_amt/1000)
			else
				player:modulate(util.linlin(1,7,0,1,slide_or_modulate))
			end
			player:play_note(note, velocity, duration/subdivision)
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
			meta:advance_all()
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

function get_page_name()
	local p
	if params:get('alt_page') == 1 then
		p = alt_page_names[params:get('page')]
	else
		p = page_names[params:get('page')]
	end
	return p
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
	--return val_buffers[track][page]
	return data:get_step_val(track,page,data:get_page_val(track,page,'pos'))
end

function get_mod_key()
	return mod_names[params:get('mod')]
end

function get_overlay()
	return overlay_names[params:get('overlay')]
end

function set_overlay(n)
	params:set('overlay',tab.key(overlay_names,n))
end

function highlight(l) -- level number
	local o = 15
	if l == LOW then
		o = 3
	elseif l == MED then
		o = 7
	elseif l == HIGH then
		o = 15
	else
		o = l + 2
	end

	return util.clamp(o,0,15)
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