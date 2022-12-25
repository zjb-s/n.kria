local nb = require 'k2z/lib/nb/nb'
include "lib/players/midi"


Prms = {}

-- todo add pattern copying and pasting
-- todo add option for keeping loop,rate,etc between patterns or not
-- todo overhaul this whole page to allow recursion: i want to add 16 copies of the whole "tracks" section but i don't think i can with the current architecture.

function Prms:add()

	params:add_separator('GLOBAL')
	params:add_number('page', 'page', 1,6,1)
	params:add_binary('alt_page','alt page?', 'toggle')
	params:add_binary('playing', 'playing?', 'toggle')
	params:add_number('active_track', 'active track', 1,NUM_TRACKS,1)
	params:add_option('mod','mod key held', mod_names, 1)
	params:add_number('scale_num','selected scale',1,NUM_SCALES,1)
	params:add_number('pattern','pattern',1,NUM_PATTERNS,1)
	params:add_option('overlay','overlay',{'none','time','config'},1)
	params:add_number('global_clock_div','global clock divisor',1,16,1)

	-- config, hide these
	params:add_binary('note_div_sync','note division sync','toggle')
	params:add_binary('div_cue', 'division cueing', 'toggle')
	params:add_option('div_sync','division sync', div_sync_modes)
	params:add_binary('note_sync','note sync', 'toggle')
	params:add_option('loop_sync','loop sync',div_sync_modes)

	params:add_group('scale data', 112)
	for i=1,16 do
		for j=1,7 do
			local default_value = scale_defaults[i][j]
			params:add_number('scale_'..i..'_deg_'..j,'scale_'..i..'_deg_'..j,0,7,default_value)
		end
	end
	add_midi_players()
	self:add_tracks()
end

params.action_read = function(filename, name, pset_number)
	for _, player in pairs(nb:get_players()) do
		print("PLAYER")
		tab.print(player)
		player:stop_all()
	end
end

function Prms:add_tracks()

	for t=1,NUM_TRACKS do
		params:add_separator('TRACK ' .. t)
		nb:add_param("voice_t"..t, 't '..t.." voice")
		params:add_option('playmode_t'..t,'t'..t..' play mode', play_modes,1)
		params:add_binary('pipo_dir_t'..t,'pipo_dir_t'..t,'toggle',1)
		params:add_binary('mute_t'..t, 'mute?', 'toggle', 0)


		-- positions
		params:add_group('t'..t..' positions', 7)
		for k,v in ipairs(combined_page_list) do
			params:add_number('pos_'..v..'_t'..t, 't'..t..' '..v..' pos', 1, 16,1)
		end

		-- loops
		params:add_group('t'..t..' loops', 14)
		for k,v in ipairs(combined_page_list) do
			if v == 'scale' or v == 'pattern' then break end
			params:add_number('loop_first_'..v..'_t'..t, 'loop_first_'..v..'_t'..t, 1, 16,1)
			params:add_number('loop_last_'..v..'_t'..t, 'loop_last_'..v..'_t'..t, 1, 16,6)
		end

		-- divisors
		params:add_group('t'..t..' divisors', 14)
		for k,v in ipairs(combined_page_list) do
			if v == 'scale' or v == 'pattern' then break end
			params:add_number('divisor_'..v..'_t'..t, 't'..t..' '..v..' divisor', 1,16,1)
			params:add_number('cued_divisor_'..v..'_t'..t, 't'..t..' '..v..' divisor', 0,16,0)
		end


		-- data
		params:add_group('t'.. t .. ' raw data', 329)
		for k,v in ipairs(combined_page_list) do
			if v == 'scale' or v == 'pattern' then break end -- no need for more params for these pages
			if v == 'octave' then 
				params:add_number('data_octave_shift_t'..t,'data_octave_shift_t'..t, 1, 5, 3)
			elseif v == 'gate' then
				params:add_number('data_gate_shift_t'..t,'data_gate_shift_t'..t,1,16,8)
			end

			params:add_number('data_t'..t..'_'..v..'_counter','data_t'..t..'_'..v..'_counter',1,99,1)

			for i=1,16 do
				if v == 'trig' then -- just for trig page...
					params:add_binary('data_trig_'..i..'_t'..t, 'data_trig_'..i..'_t'..t, 'toggle', 0)
				else
					params:add_number('data_'..v..'_'..i..'_t'..t, 'data_'..v..'_'..i..'_t'..t
					,	page_ranges[k][1]
					,	page_ranges[k][2]
					,	page_ranges[k][3]
					)
				end
				if v == 'retrig' then
					params:add_number('data_subtrig_count_'..i..'_t'..t,'data_subtrigs_'..i..'_t'..t,0,5,1)
					for st=1,5 do
						params:add_binary('data_subtrig_'..st..'_step_'..i..'_t'..t,'data_subtrig_'..st..'_step_'..i..'_t'..t,'toggle')
						if st==1 then
							params:set('data_subtrig_'..st..'_step_'..i..'_t'..t,1)
						end
					end
				end
				params:add_number('data_'..v..'_prob_'..i..'_t'..t,'data_prob_'..v..'_t'..t,1,4,4)
			end
		end
	end
end

return Prms