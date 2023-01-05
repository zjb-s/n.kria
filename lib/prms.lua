--[[
WHAT GOES IN THIS FILE:
- param declarations
]]--

local nb = include('n.kria/lib/nb/lib/nb')

Prms = {}

function Prms:add()

	params:add_separator('N.KRIA')
	params:add_binary('debug','DEBUG','toggle',0)
	params:add_binary('playing', 'PLAYING?', 'toggle')
	params:add_number('root_note','ROOT NOTE',0,11,0,
		function(x) return mu.note_num_to_name(x.value) end
	)
	params:add_number('stretch','STRETCH',-64,64,0,
		function(x) return x.value > 0 and '+'..x.value or x.value end
	)
	params:add_number('push','PUSH',-64,64,0,
		function(x) return x.value > 0 and '+'..x.value or x.value end
	)
	params:add_number('swing','SWING',50,99,55,function(x) return x.value..'%' end)
	params:add_number('global_clock_div','CLOCK DIVISION',1,16,1,
		function(x) return division_names[x.value] end
	)
	params:add_trigger('reset_all','RESET')
	params:set_action('reset_all',function(x) meta:reset_all() end)
	params:add_trigger('advance_all','ADVANCE ALL')
	params:set_action('advance_all',function() meta:advance_all() end)
	
	params:add_group('OPTIONS',5)
	params:add_binary('note_div_sync','NOTE DIV SYNC','toggle')
	params:add_binary('div_cue', 'DIV CUE', 'toggle')
	params:add_option('div_sync','DIV SYNC', div_sync_modes)
	params:add_binary('note_sync','NOTE SYNC', 'toggle')
	params:add_option('loop_sync','LOOP SYNC',div_sync_modes)
	
	params:add_group('GLOBAL DATA',11)
	params:add_binary('swing_this_step','swing_this_step','toggle')
	params:add_number('active_track', 'active track', 1,NUM_TRACKS,1)
	params:add_option('mod','mod key held', mod_names, 1)
	params:add_number('scale_num','selected scale',1,NUM_SCALES,1)
	params:add_option('overlay','overlay',overlay_names,1)
	params:add_number('page', 'page', 1,6,1)
	params:add_binary('alt_page','alt page?', 'toggle')
	params:add_number('active_pattern','pattern',1,NUM_PATTERNS,1)
	params:add_number('cued_pattern','cued pattern',0,99,1)
	params:add_number('pattern_quant','pattern_quant',1,16,1)
	params:add_number('pattern_quant_pos','pattern_quant_pos',1,16,1)
	params:hide('GLOBAL DATA')

	params:add_group('ms_data',134) -- meta-sequence
	params:add_number('ms_first','ms_loop_first',1,64,1)
	params:add_number('ms_last','ms_loop_last',1,64,4)
	params:add_number('ms_pos','ms_pos',1,64,1)
	params:add_number('ms_cursor','ms_cursor',1,64,1)
	params:add_number('ms_duration_pos','ms_duration_pos',1,99,1)
	params:add_binary('ms_active','ms_active','toggle')
	for i=1,64 do
		params:add_number('ms_pattern_'..i,'ms_'..i..'_pattern',1,64,1)
		params:add_number('ms_duration_'..i,'ms_'..i..'_duration',1,16,1)
	end
	params:hide('ms_data')

	params:add_group('scale data', 112)
	for i=1,16 do
		for j=1,7 do
			local default_value = scale_defaults[i][j]
			params:add_number('scale_'..i..'_deg_'..j,'scale_'..i..'_deg_'..j,0,7,default_value)
		end
	end
	params:hide('scale data')

	self:add_tracks()
	params:add_separator("VOICE CONTROLS")
	nb:add_player_params()
end

params.action_read = function(filename, name, pset_number)
	for _, player in pairs(nb:get_players()) do
		player:stop_all()
	end
end

function Prms:add_tracks()

	for t=1,NUM_TRACKS do
		params:add_separator('TRACK ' .. t)
		nb:add_param("voice_t"..t, "OUTPUT")

		params:add_group('T'..t..' OPTIONS',7)
		params:add_option('play_mode_t'..t,'PLAY MODE', play_modes,1)
		params:add_binary('mute_t'..t, 'MUTE', 'toggle')
		params:add_trigger('reset_t'..t,'RESET')
		params:set_action('reset_t'..t,function(x) meta:reset_track(t) end)
		params:add_trigger('advance_t'..t,'ADVANCE')
		params:set_action('advance_t'..t,function() meta:advance_track(t) end)
		params:add_binary('stretchable_t'..t,'STRETCHABLE','toggle',1)
		params:add_binary('pushable_t'..t,'PUSHABLE','toggle',1)
		params:add_binary('trigger_clock_t'..t,'TRIGGER CLOCK','toggle',0)
		
		params:add_group('track_data_t'..t,2)
		params:add_number('octave_shift_t'..t,'octave_shift_t'..t, 1, 8, 4)
		params:add_number('gate_shift_t'..t,'gate_shift_t'..t,1,16,8)
		params:hide('track_data_t'..t)
		
		
		for p=1,NUM_PATTERNS do
			params:add_group('P'..p..' T'..t..' DATA',369)

			for k,v in ipairs(combined_page_list) do
				if v == 'scale' or v == 'pattern' then break end

				params:add_number('pos_'..v..'_t'..t..'_p'..p, 't'..t..' '..v..' pos', 1, 16,1)
				params:add_number('loop_first_'..v..'_t'..t..'_p'..p, 'loop_first_'..v..'_t'..t, 1, 16,1)
				params:add_number('loop_last_'..v..'_t'..t..'_p'..p, 'loop_last_'..v..'_t'..t, 1, 16,6)
				params:add_number('divisor_'..v..'_t'..t..'_p'..p, 't'..t..' '..v..' divisor', 1,16,1)
				params:add_number('cued_divisor_'..v..'_t'..t..'_p'..p, 't'..t..' '..v..' divisor', 0,16,0)
				params:add_number('counter_'..v..'_t'..t..'_p'..p,'counter_'..v..'_t'..t,1,99,1)
				params:add_binary('pipo_dir_'..v..'_t'..t..'_p'..p,'pipo_dir_'..v..'_t'..t..'_p'..p,'toggle',1)

				for i=1,16 do
					if v == 'trig' then -- just for trig page...
						params:add_binary('data_trig_'..i..'_t'..t..'_p'..p, 'data_trig_'..i..'_t'..t, 'toggle', 0)
					else
						params:add_number('data_'..v..'_'..i..'_t'..t..'_p'..p, 'data_'..v..'_'..i..'_t'..t
						,	page_ranges[k][1]
						,	page_ranges[k][2]
						,	page_ranges[k][3]
						)
					end
					if v == 'retrig' then
						params:add_number('data_subtrig_count_'..i..'_t'..t..'_p'..p,'data_subtrigs_'..i..'_t'..t,0,5,1)
						for st=1,5 do
							params:add_binary('data_subtrig_'..st..'_step_'..i..'_t'..t..'_p'..p,'data_subtrig_'..st..'_step_'..i..'_t'..t,'toggle')
							if st==1 then
								params:set('data_subtrig_'..st..'_step_'..i..'_t'..t..'_p'..p,1)
							end
						end
					end
					params:add_number('data_'..v..'_prob_'..i..'_t'..t..'_p'..p,'data_prob_'..v..'_t'..t,1,4,4)
				end
			end

			params:hide('P'..p..' T'..t..' DATA')
		end
	end
end

return Prms
