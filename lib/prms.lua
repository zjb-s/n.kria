--[[
WHAT GOES IN THIS FILE:
- param declarations
]]
--

local nb = include('n.kria/lib/nb/lib/nb')

local data = include('n.kria/lib/data_functions')
local rw = include('n.kria/lib/pset_rewriter')

Prms = {}

function Prms:script_mode_switch()
	local extended_param_names = {
		globals = {
			'stretch'
			, 'push'
		, 'advance_all'
		, 'reset_all'
		}
		,
		per_track = {
			'stretchable'
			, 'pushable'
		, 'trigger_clock'
		, 'param_clock'
		, 'advance'
		, 'reset'
		, 'div_group'
		, 'loop_group'
		}
	}
	params:set_action('script_mode', function(x)
		for _, v in pairs(extended_param_names.globals) do
			if x == 2 then
				params:show('global_' .. v)
			else
				params:hide('global_' .. v)
			end
		end
		for t = 1, NUM_TRACKS do
			for _, v in pairs(extended_param_names.per_track) do
				if x == 2 then
					params:show(v .. '_t' .. t)
					params:show('T' .. t .. ' LOOP GROUPS')
					params:show('T' .. t .. ' DIV GROUPS')
					for _, v in pairs(pages_with_steps) do
						params:show('loop_group_' .. v .. '_t' .. t)
						params:show('div_group_' .. v .. '_t' .. t)
					end
				else
					params:hide(v .. '_t' .. t)
					params:hide('T' .. t .. ' LOOP GROUPS')
					params:hide('T' .. t .. ' DIV GROUPS')
					for _, v in pairs(pages_with_steps) do
						params:hide('loop_group_' .. v .. '_t' .. t)
						params:hide('div_group_' .. v .. '_t' .. t)
					end
				end
			end
		end
		_menu.rebuild_params()
	end)
end

function Prms:add()
	data:init()
	params:add_separator('N.KRIA')
	self:add_globals()
	self:script_mode_switch()
	self:add_tracks()
	params:add_separator("VOICE CONTROLS")
	nb:add_player_params()
end

params.action_read = function(filename, name, pset_number)
	local patternfile = filename .. ".kriapattern"
	if util.file_exists(patternfile) then
		data.patterns = tab.load(patternfile)
	elseif params.last_chance then
		params.last_chance = nil
	else
		-- try *one time* to convert it.
		params.last_chance = true
		rw.rewrite(filename)
		params:read(filename)
	end
	for _, player in pairs(nb:get_players()) do
		player:stop_all()
	end
end

params.action_write = function(filename, name, pset_number)
	tab.save(data.patterns, filename .. ".kriapattern")
end

function Prms:add_globals()
	data:add_binary('playing', 'PLAYING?', 'toggle')
	data:add_number('root_note', 'ROOT NOTE', 0, 11, 0,
		function(x) return mu.note_num_to_name(x.value) end
	)
	data:add_number('stretch', 'STRETCH', -32, 32, 0,
		function(x) return x.value > 0 and '+' .. x.value or x.value end
	)
	data:add_number('push', 'PUSH', -15, 14, 0,
		function(x) return x.value > 0 and '+' .. x.value or x.value end
	)
	data:add_number('swing', 'SWING', 50, 99, 55, function(x) return x.value .. '%' end)
	data:add_number('clock_div', 'CLOCK DIVISION', 1, 16, 1,
		function(x) return division_names[x.value] end
	)

	params:add_option('script_mode', 'SCRIPT MODE', { 'classic', 'extended' }, 1)

	params:add_group('OPTIONS', 7)
	data:add_binary('note_div_sync', 'NOTE DIV SYNC', 'toggle')
	data:add_binary('div_cue', 'DIV CUE', 'toggle')
	data:add_option('div_sync', 'DIV SYNC', div_sync_modes)
	data:add_binary('note_sync', 'NOTE SYNC', 'toggle')
	data:add_option('loop_sync', 'LOOP SYNC', div_sync_modes)
	data:add_trigger('reset_all', 'RESET')
	data:set_action('reset_all', function(x) meta:reset_all() end)
	data:add_trigger('advance_all', 'ADVANCE ALL')
	data:set_action('advance_all', function() meta:advance_all() end)

	params:add_group('GLOBAL DATA', 12)
	data:add_binary('swing_this_step', 'swing_this_step', 'toggle')
	data:add_number('active_track', 'active track', 1, NUM_TRACKS, 1)
	data:add_option('mod', 'mod key held', mod_names, 1)
	data:add_number('scale_num', 'selected scale', 1, NUM_SCALES, 1)
	data:add_option('overlay', 'overlay', overlay_names, 1)
	data:add_option('patcher', 'patcher', patchers, 1)
	data:add_number('page', 'page', 1, 6, 1)
	data:add_binary('alt_page', 'alt page?', 'toggle')
	data:add_number('active_pattern', 'pattern', 1, NUM_PATTERNS, 1)
	data:set_action('active_pattern', function(x) data.pattern = x end)
	data:add_number('cued_pattern', 'cued pattern', 0, 99, 1)
	data:add_number('pattern_quant', 'pattern_quant', 1, 99, 1)
	data:add_number('pattern_quant_pos', 'pattern_quant_pos', 1, 99, 1)
	params:hide('GLOBAL DATA')

	params:add_group('ms_data', 134) -- meta-sequence
	data:add_number('ms_first', 'ms_loop_first', 1, 64, 1)
	data:add_number('ms_last', 'ms_loop_last', 1, 64, 4)
	data:add_number('ms_pos', 'ms_pos', 1, 64, 1)
	data:add_number('ms_cursor', 'ms_cursor', 1, 64, 1)
	data:add_number('ms_duration_pos', 'ms_duration_pos', 1, 99, 1)
	data:add_binary('ms_active', 'ms_active', 'toggle')
	for i = 1, 64 do
		params:add_number('global_ms_pattern_' .. i, 'ms_' .. i .. '_pattern', 1, 64, 1)
		params:add_number('global_ms_duration_' .. i, 'ms_' .. i .. '_duration', 1, 16, 1)
	end
	params:hide('ms_data')

	params:add_group('scale data', 112)
	for i = 1, 16 do
		local scale = data.scales[i]
		for j = 1, 7 do
			local default_value = scale_defaults[i][j]
			scale:add_number(j, 'scale_' .. i .. '_deg_' .. j, 0, 7, default_value)
		end
	end
	params:hide('scale data')
end

function Prms:add_tracks()
	params:add_separator('TRACK CONTROLS')

	for t = 1, NUM_TRACKS do
		local track = data.tracks[t]
		params:add_group(lexi_names[t], 30)
		nb:add_param("voice_t" .. t, "T" .. t .. " OUTPUT")
		track.player = params:lookup_param('voice_t' .. t)
		track:add_option('play_mode', 'PLAY MODE', play_modes, 1)
		track:add_binary('mute', 'MUTE', 'toggle')
		track:add_trigger('reset', 'RESET')
		track:set_action('reset', function(x) transport:reset_track(t) end)
		track:add_trigger('advance', 'ADVANCE')
		track:set_action('advance', function()
			if params:get('param_clock_t' .. t) == 1 then
				transport:advance_track(t)
				-- print('advancing track '..t)
			end
		end)
		track:add_binary('stretchable', 'STRETCHABLE?', 'toggle', 1)
		track:add_binary('pushable', 'PUSHABLE?', 'toggle', 1)
		track:add_binary('trigger_clock', 'TRIGGER CLOCK?', 'toggle', 0)
		track:add_binary('param_clock', 'PARAM CLOCK?', 'toggle', 0)
		params:add_separator('T' .. t .. ' DIV GROUPS')
		track:add_number('div_group', 'TRACK', 0, NUM_SYNC_GROUPS, 0, function(x)
			return x.value == 0 and 'global' or x.value
		end)
		for _, v in ipairs(pages_with_steps) do
			local page = track[v]
			page:add_number('div_group', string.upper(v), 0, NUM_SYNC_GROUPS, 0,
				function(x)
					return x.value == 0 and 'track' or x.value
				end)
		end
		params:add_separator('T' .. t .. ' LOOP GROUPS')
		track:add_number('loop_group', 'TRACK', 0, NUM_SYNC_GROUPS, 0, function(x)
			return x.value == 0 and 'global' or x.value
		end)
		for _, v in ipairs(pages_with_steps) do
			local page = track[v]
			page:add_number('loop_group', string.upper(v), 0, NUM_SYNC_GROUPS, 0,
				function(x)
					return x.value == 0 and 'track' or x.value
				end)
		end

		-- params:add_binary('div_sync_t'..t,'INTERNAL DIV SYNC','toggle',0)
		-- params:add_binary('loop_sync_t'..t,'INTERNAL LOOP SYNC','toggle',0)
		-- params:add_binary('note_sync_t'..t,'INTERNAL NOTE SYNC','toggle',0)

		track:add_group('track_data', 34)
		track:add_number('octave_shift', 'octave_shift_t' .. t, 1, 8, 4)
		track:add_number('gate_shift', 'gate_shift_t' .. t, 1, 16, 8)
		for k, v in pairs(pages_with_steps) do
			local page = track[v]
			page:add_number('pos', 'data', 1, 16, 1)
			page:add_number('cued_divisor', 'data', 0, 16, 0)
			page:add_number('counter', 'data', 1, 99, 1)
			page:add_number('pipo_dir', 'data', 0, 1, 1)
		end
		track:hide('track_data')
	end
end

return Prms
