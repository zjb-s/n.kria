--[[
WHAT GOES IN THIS FILE:
- global variables

]]--

return {
	add = function()
		-- macros
		OFF=0
		LOW=2
		MED=5
		HIGH=12
		NUM_TRACKS = 4
		-- NUM_TRACKS = 7
		-- NUM_FULL_TRACKS = 4
		-- NUM_HALF_TRACKS = 3
		NUM_PATTERNS = 16
		NUM_SCALES = 16
		NUM_SYNC_GROUPS = 12

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
		,	velocity = {min=1,max=7,default=5}
		}
		pattern_page_info = {
			loop_first = {
				min = 1,
				max = 16,
				default = 1,
			},
			loop_last = {
				min = 1,
				max = 16,
				default = 6,
			},
			divisor = {
				min = 1,
				max = 16,
				default = 1,
			}
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
		lexi_names = {'ONE','TWO','THREE','FOUR','FIVE','SIX','SEVEN'}
		page_names = {'trig', 'note', 'octave', 'gate', 'scale', 'pattern'}
		alt_page_names = {'retrig', 'transpose', 'slide', 'velocity'}
		combined_page_list = {'trig','note','octave','gate','retrig','transpose','slide','velocity','scale','pattern'}
		pages_with_steps = {'trig','retrig','note','transpose','octave','slide','gate','velocity'}
		trigger_clock_pages = {'note','transpose','octave','slide','gate','velocity'}
		trig_and_retrig_pages = {'trig','retrig'}
		matrix_sources = {'note','transpose','octave','slide','gate','velocity'}
		trig_sources = {}
		mod_names = {'none','loop','time','prob'}
		play_modes = {'forward', 'reverse', 'triangle', 'drunk', 'random'}
		prob_map = {0, 25, 50, 100}
		div_sync_modes = {'none','track','all'}
		overlay_names = {'none','time','options','patchers'}
		patchers = {'advance triggers'}
		dtab_get_page_val = {
			loop_first = true
		,	loop_last = true
		,	divisor = true
		}

		blink = {
			menu = {false,false,false,false,false}
		}

		track_options = {
			'stretchable'
		,	'pushable'
		,	'trigger_clock'
		,	'param_clock'
		,	'note_sync'
		,	'div_sync'
		,	'loop_sync'
		}
		track_options_xes = {0,0,1,1,0,1,0}

		coros = {}
		value_buffer = {}
		page_clipboards = {}
		track_clipboard = {}
		pattern_clipboard = {}
		ms_step_clipboard = {}
		last_notes = {0,0,0,0}
		last_notes_raw = {0,0,0,0}
		temp_scale = {-1,-1,-1,-1,-1,-1}

		post_buffer = '-'
		loop_first = -1
		loop_last = -1
		wavery_light = MED
		waver_dir = 1
		waver_flipflop = true
		last_touched_page = 'trig'
		last_touched_track = 1
		last_touched_ms_step = 1
		last_touched_pattern = 1
		pulse_indicator = 1
		global_clock_counter = 1
		just_pressed_clipboard_key = false
		just_saved_pattern = false
		just_pressed_track = false

		-- buffers
		kbuf = {} -- key state buffer, true/false
		onboard_key_states = {false,false,false}
	end
}