--
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~ k2z ~~~~~~~~~~~~~~
-- ~~~~~~~~~ by zbs ~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~ kria port native to lua ~~~
-- 0.1 ~~~~~~~~~~~~~~~~~~~~~~~~~
-- 
-- k2: reset
-- k3: play
-- k1+k2: time overlay (ansible k1)
-- k1:k3: config overlay (ansible k2)
--
-- thanks for everything, @tehn

screen_graphics = include('lib/screen_graphics')
grid_graphics = include('lib/grid_graphics')
Prms = include('lib/prms')
Onboard = include('lib/onboard')
gkeys = include('lib/gkeys')
meta = include('lib/meta')
nb = include("lib/nb/nb")
mu = require 'musicutil'


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
page_names = {'trig', 'note', 'octave', 'gate','scale','patterns'}
alt_page_names = {'retrig', 'transpose', 'slide'}
combined_page_list = {'trig','note','octave','gate','retrig','transpose','slide','scale','patterns'}
mod_names = {'none','loop','time','prob'}
play_modes = {'forward', 'reverse', 'triangle', 'drunk', 'random'}
prob_map = {0, 25, 50, 100}
div_sync_modes = {'none','track','all'}

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

data = {}
function data:get_track_val(track,name) return params:get(name..'_t'..track) end
function data:get_page_val(track,page,name) return params:get(name..'_'..page..'_t'..track) end
function data:get_step_val(track,page,step) return params:get('data_'..page..'_'..step..'_t'..track) end
function data:set_track_val(track,name,new_val) params:set(name..'_t'..track,new_val) end
function data:set_page_val(track,page,name,new_val) params:set(name..'_'..page..'_t'..track,new_val) end
function data:set_step_val(track,page,step,new_val) params:set('data_'..page..'_'..step..'_t'..track,new_val) end
function data:delta_track_val(track,name,d) params:delta(name..'_t'..track,d) end
function data:delta_page_val(track,page,name,d) params:delta(name..'_'..page..'_t'..track,d) end
function data:delta_step_val(track,page,step,d) params:delta('data_'..page..'_'..step..'_t'..track,d) end
-- no support for probability or subtrigs

loop_first = -1
loop_last = -1
wavery_light = MED
waver_dir = 1
shift = false

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
	post(':-)')
end

function key(n,d) Onboard:key(n,d) end
function enc(n,d) Onboard:enc(n,d) end
function g.key(x,y,z) gkeys:key(x,y,z) end

val_buffers = {}
function init_val_buffers()
	for i=1,NUM_TRACKS do
		table.insert(val_buffers,{})
		for k,v in ipairs(combined_page_list) do
			if v == 'scale' or v == 'patterns' then break end
			val_buffers[i][v] = 
				params:get('data_'..v..'_'..params:get('pos_'..v..'_t'..i)..'_t'..i)
		end
	end
end

function clock.transport.start() params:set('playing',1); post('play') end
function clock.transport.stop() params:set('playing',0); post('stop') end

function init()
	nb:init()
	init_grid_buffers()
	Prms:add()
	init_val_buffers()
	clock.run(visual_ticker)
	clock.run(step_ticker)
	clock.run(intro)
end

function make_scale()
	local new_scale = {0,0,0,0,0,0,0}
	local table_from_params = {}
	local output_scale = {}
	for i=1,7 do
		table.insert(table_from_params,params:get('scale_'..params:get('scale_num')..'_deg_'..i))
	end
	for i=2,7 do
		new_scale[i] = new_scale[i-1] + table_from_params[i]
	end
	return new_scale
end

function note_clock(track,note,duration,slide_amt) 
	local player = params:lookup_param("voice_t"..track):get_player()
	local velocity = 1.0
	local divider = data:get_page_val(track,'trig','divisor')
	local pos = data:get_page_val(track,'retrig','pos')
	local subdivision = params:get('data_subtrig_count_'..pos..'_t'..track)
	for i=1,subdivision do
		if params:get('data_subtrig_'..i..'_step_'..pos..'_t'..track) == 1 then
			player:set_slew(slide_amt/1000)
			player:play_note(note, velocity, duration/subdivision)
		end
		clock.sleep(clock.get_beat_sec()*divider/(4*subdivision))
	end
end

function update_val(track,page)
	val_buffers[track][page] =
	    params:get('data_'..page..'_'..params:get('pos_'..page..'_t'..track)..'_t'..track)
	if page == 'trig' then
	    if current_val(track,'trig') == 1 then
	        meta:note_out(track)
	    end
	end
end

function step_ticker()
	while true do
		clock.sync(1/4)
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

function current_val(track,page)
	return val_buffers[track][page]
end

function get_mod_key()
	return mod_names[params:get('mod')]
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