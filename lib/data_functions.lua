--[[
WHAT GOES IN THIS FILE:
- wrappers for interacting w params sporting long annoying names
]] --
if Data == nil then

	local pattern_page_attrs = {
		loop_first = true,
		loop_last = true,
		divisor = true,
	}

	Data = {}

	local global_meta = {
		__index = function(t, key)
			if params[key] then
				return function(self, id, ...)
					-- do the params part
					local new_id = 'global_' .. id
					local f = params[key]
					f(params, new_id, ...)
					local p = params:lookup_param(new_id)
					self[id] = p
				end
			end
			return nil
		end
	}

	local track_meta = {
		__index = function(t, key)
			if params[key] then
				return function(self, id, ...)
					-- do the params part
					local new_id = id .. '_t' .. self.idx
					local f = params[key]
					f(params, new_id, ...)
					local p = params:lookup_param(new_id)
					self[id] = p
				end
			end
			return nil
		end
	}

	local pattern_track_meta = {
		__index = function(t, key)
			if params[key] == nil then return nil end
			return function(self, id, ...)
				-- do the params part
				local new_id = id .. '_t' .. self.idx .. '_p' .. self.pattern
				local f = params[key]
				f(params, new_id, ...)
				local p = params:lookup_param(new_id)
				self[id] = p
			end
		end
	}

	local page_meta = {
		__index = function(t, key)
			if params[key] == nil then return nil end
			return function(self, id, ...)
				-- do the params part
				local new_id = id .. '_' .. self.id .. '_t' .. self.track
				local f = params[key]
				f(params, new_id, ...)
				local p = params:lookup_param(new_id)
				self[id] = p
			end
		end
	}

	local pattern_page_meta = {
		__index = function(t, key)
			if params[key] == nil then return nil end
			return function(self, id, ...)
				local new_id = id .. '_' .. self.id .. '_t' .. self.track .. '_p' .. self.pattern
				local f = params[key]
				f(params, new_id, ...)
				local p = params:lookup_param(new_id)
				self[id] = p
			end
		end
	}

	local step_meta = {
		__index = function(t, key)
			if params[key] == nil then return nil end
			return function(self, id, ...)
				local new_id
				if id == 'step' then
					new_id = "data_" .. self.page .. '_' .. self.i .. '_t' .. self.track .. '_p' .. self.pattern
				else
					new_id = (
						"data_" .. self.page .. '_' .. id .. '_'
							.. self.i .. '_t' .. self.track .. '_p' .. self.pattern
						)
				end
				local f = params[key]
				f(params, new_id, ...)
				local p = params:lookup_param(new_id)
				self[id] = p
			end
		end
	}

	setmetatable(Data, global_meta)

	Data.pattern = nil

	function Data:init()
		-- Two layers — one for data that's stored per-pattern, and one
		-- that's just tracks, for non-pattern data.
		self.patterns = {}
		-- for p = 1, NUM_PATTERNS do
		-- 	local pat = { idx = p }
		-- 	for t = 1, NUM_TRACKS do
		-- 		local trk = { idx = t, pattern = p }
		-- 		setmetatable(trk, pattern_track_meta)
		-- 		for _, v in ipairs(pages_with_steps) do
		-- 			local page = { pattern = p, track = t, id = v }
		-- 			setmetatable(page, pattern_page_meta)
		-- 			trk[v] = page
		-- 			for i = 1, 16 do
		-- 				local step = { pattern = p, track = t, page = v, i = i }
		-- 				setmetatable(step, step_meta)
		-- 				page[i] = step
		-- 			end
		-- 		end
		-- 		pat[t] = trk
		-- 	end
		-- 	self.patterns[p] = pat
		-- end
		self.tracks = {}
		for t = 1, NUM_TRACKS do
			local trk = { idx = t }
			setmetatable(trk, track_meta)
			for _, v in ipairs(pages_with_steps) do
				local page = { track = t, id = v }
				setmetatable(page, page_meta)
				trk[v] = page
			end
			self.tracks[t] = trk
		end
	end

	-- GET
	function Data:get_global_val(name)
		return self[name]:get()
	end

	function Data:get_track_val(track, name)
		return self.tracks[track][name]:get()
	end

	function Data:get_page_val(track, page, name)
		if pattern_page_attrs[name] then
			local default = pattern_page_info[name].default
			local pt = self.patterns[self.pattern]
			if pt == nil then return default end
			local tr = pt[track]
			if tr == nil then return default end
			local pg = tr[page]
			if pg == nil then return default end
			local result = pg[name]
			if result == nil then return default end
			return result
		else
			local pp = self.tracks[track][page]
			if type(pp) ~= 'table' then
				print("track is", track, "page is", page)
			end			
			local param = pp[name]
			if type(param) ~= 'table' then
				print("page is", page, param)
				tab.print(pp)
			end
			return param:get()
		end
	end

	function Data:get_loop_first(track, page)
		local temp = self.tracks[track][page].temp_loop_first
		if type(temp) == 'number' then return temp end
		return self:get_page_val(track, page, 'loop_first')
	end

	function Data:get_loop_last(track, page)
		local temp = self.tracks[track][page].temp_loop_last
		if type(temp) == 'number' then return temp end
		return self:get_page_val(track, page, 'loop_last')
	end

	function Data:get_pos(track, page)
		local temp = self.tracks[track][page].temp_pos
		if type(temp) == 'number' then return temp end
		return self:get_page_val(track, page, 'pos')
	end

	function Data:get_player(track)
		return self.tracks[track].player:get_player()
	end

	function Data:get_step_val(track, page, step, thing)
		local default
		if thing == nil then
			thing = 'step'
			default = page_defaults[page].default
		elseif thing == 'prob' then
			default = 4
		elseif thing == 'subtrig' then
			default = 1
		end

		local pat = self.patterns[self.pattern]
		if pat == nil then return default end
		local tr = pat[track]
		if tr == nil then return default end
		local pg = tr[page]
		if pg == nil then return default end
		-- if type(pg) ~= 'table' then
		-- 	print("page is", page, pg)
		-- end
		local st = pg[step]
		if st == nil then return default end
		local val = st[thing]
		if type(val) == 'table' then
			print("oh no", track, page, step, thing, "it was")
			tab.print(val)
		end
		if val == nil then return default end
		return val
	end

	-- SET
	function Data:set_global_val(name, new_val)
		self[name]:set(new_val)
	end

	function Data:set_track_val(track, name, new_val)
		self.tracks[track][name]:set(new_val)
	end

	function Data:set_page_val(track, page, name, new_val)
		if pattern_page_attrs[name] then
			local info = pattern_page_info[name]
			local vv = util.clamp(new_val, info.min, info.max)
			self.patterns[self.pattern][track][page][name] = vv
		else
			self.tracks[track][page][name]:set(new_val)
		end
	end

	function Data:set_step_val(track, page, step, new_val, thing)
		local vv = new_val
		if thing == nil then
			local defaults = page_defaults[page]
			thing = 'step'
			vv = util.clamp(new_val, defaults.min, defaults.max)
		elseif thing == 'prob' then
			vv = util.clamp(new_val, 1, 4)
		elseif thing == 'subtrig' then
			vv = util.clamp(new_val, 1, 31)
		end
		self.patterns[self.pattern][track][page][step][thing] = vv
	end

	-- DELTA
	function Data:delta_global_val(name, d)
		self[name]:delta(d)
	end

	function Data:delta_track_val(track, name, d)
		self.tracks[track][name]:delta(d)
	end

	function Data:delta_page_val(track, page, name, d)
		if pattern_page_attrs[name] then
			local default = pattern_page_info[name].default
			local val = self.patterns[self.pattern][track][page][name] or default
			self.patterns[self.pattern][track][page][name] = val + d
		else
			return self.tracks[track][page][name]:delta(d)
		end
	end

	function Data:delta_step_val(track, page, step, d, thing)
		if thing == nil then thing = 'step' end
		local info = page_defaults[page]
		local val = self:get_step_val(track, page, step, thing)
		self:set_step_val(track, page, step, val + d, thing)
	end

	function Data:get_subtrig(track, step, subtrig)
		local st = self:get_step_val(track, 'retrig', step, 'subtrig')
		return bit32.extract(st, subtrig - 1)
	end

	function Data:set_subtrig(track, step, subtrig, one_or_zero)
		local st = self:get_step_val(track, 'retrig', step, 'subtrig')
		st = bit32.replace(st, one_or_zero, subtrig - 1)
		self:set_step_val(track, 'retrig', step, st, 'subtrig')
	end
end
return Data
