local sc = {}

local beat_amounts = {
	"sixteenth", 
	"eighth triplet", 
	"dotted sixteenth", 
	"eighth", 
	"triplet", 
	"dotted eighth", 
	"quarter", 
	"dotted quarter"
}

local beat_values = {
	1/4,
	1/3,
	3/8,
	1/2,
	2/3,
	3/4,
	1,
	3/2,
}

local loop_length = 0.5

function sc.init()
	audio.level_cut(1.0)
	audio.level_adc_cut(1)
	audio.level_eng_cut(1)

	-- 1
	softcut.level(1, 1.0)
	softcut.level_slew_time(1, 0)
	softcut.level_input_cut(1, 1, 1.0)
	softcut.level_input_cut(2, 1, 1.0)
	softcut.pan(1, 1)

	softcut.play(1, 1)
	softcut.rate(1, 1)
	softcut.rate_slew_time(1, 0)
	softcut.loop_start(1, 1)
	softcut.loop_end(1, 1 + loop_length)
	softcut.loop(1, 1)
	softcut.fade_time(1, 0.1)
	softcut.rec(1, 1)
	softcut.rec_level(1, 1)
	softcut.pre_level(1, 0.75)
	softcut.position(1, 1)
	softcut.enable(1, 1)

	softcut.filter_dry(1, 0.125);
	softcut.filter_fc(1, 1200);
	softcut.filter_lp(1, 0);
	softcut.filter_bp(1, 1.0);
	softcut.filter_rq(1, 2.0);

	-- 2
	softcut.level(2, 1.0)
	softcut.level_slew_time(2, 0)
	softcut.level_input_cut(1, 2, 1.0)
	softcut.level_input_cut(2, 2, 1.0)
	softcut.pan(2, -1)

	softcut.play(2, 1)
	softcut.rate(2, 1)
	softcut.rate_slew_time(2, 0.25)
	softcut.loop_start(2, 1)
	softcut.loop_end(2, 1 + loop_length)
	softcut.loop(2, 1)
	softcut.fade_time(2, 0.1)
	softcut.rec(2, 1)
	softcut.rec_level(2, 1)
	softcut.pre_level(2, 0.75)
	softcut.position(2, 1)
	softcut.enable(2, 1)

	softcut.filter_dry(2, 0);
	softcut.filter_fc(2, 1200);
	softcut.filter_lp(2, 0);
	softcut.filter_bp(2, 1.0);
	softcut.filter_rq(2, 2.0);

	add_sc_params()
end

function set_delay_rate()
	local base_rate
	if params:get("delay_style") == 1 then
		-- rate
		base_rate = params:get("delay_rate")
	elseif params:get("delay_style") == 2 then
		local beat_sec = clock.get_beat_sec()
		local delay_value = beat_values[params:get("delay_beats")]
		local delay_duration = beat_sec * delay_value
		base_rate = loop_length/delay_duration
		params:set("delay_rate", base_rate)
	end
	softcut.rate(1, base_rate * 2^params:get('delay_skew'))
	softcut.rate(2, base_rate * 2^(-params:get('delay_skew')))
end

function add_sc_params()
	params:add_group("DELAY", 9)

	params:add { id = "delay", name = "level", type = "control",
		controlspec = controlspec.new(0, 1, 'lin', 0, 0.5, ""),
		action = function(x)
			softcut.level(1, x)
			softcut.level(2, x)
		end
	}
	params:add { id = "delay_cutoff", name = "band center", type = "control",
		controlspec = controlspec.WIDEFREQ,
		action = function(x)
			softcut.filter_fc(1, x)
			softcut.filter_fc(2, x)
		end
	}
	params:add { id = "delay_q", name = "band width", type = "control",
		controlspec = controlspec.new(0.1, 4.0, 'lin', 0.1, 2, ""),
		action = function(x)
			softcut.filter_rq(1, x)
			softcut.filter_rq(2, x)
		end
	}
	params:add_option("delay_style", "style", {"free", "sync"}, 1)
	params:set_action("delay_style", function() 
		if params:get("delay_style") == 1 then
			params:hide("delay_beats")
			params:show("delay_rate")
		elseif params:get("delay_style") == 2 then
			params:hide("delay_rate")
			params:show("delay_beats")
		end
		_menu.rebuild_params()
		set_delay_rate()
	end)
	params:add { id = "delay_rate", name = "delay rate", type = "control",
		controlspec = controlspec.new(0.1, 2.0, 'exp', 0, 1, "", 0.002),
		action = set_delay_rate
	}
	params:add_option(
		"delay_beats", 
		"delay beats", 
		beat_amounts, 6)
	params:set_action("delay_beats", set_delay_rate)

	params:add { id = "delay_skew", name = "delay skew", type = "control",
		controlspec = controlspec.new(-1.0, 1.0, 'lin', 0, 0, '', 0.002),
		action = set_delay_rate
	}
	params:add { id = "delay_feedback", name = "delay feedback", type = "control",
		controlspec = controlspec.new(0, 1.0, 'lin', 0, 0.75, ""),
		action = function(x)
			softcut.pre_level(1, x)
			softcut.pre_level(2, x)
		end
	}
	params:add { id = "delay_width", name = "delay width", type = "control",
		controlspec = controlspec.new(0.0, 1.0, 'lin', 0, 1, ""),
		action = function(x)
			softcut.pan(1, -x)
			softcut.pan(2, x)
		end
	}
end

return sc
