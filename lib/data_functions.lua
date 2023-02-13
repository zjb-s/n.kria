--[[
WHAT GOES IN THIS FILE:
- wrappers for interacting w params sporting long annoying names
]]--

local Data = {}

Data.pattern = nil

-- GET
function Data:get_global_val(name)
	return params:get('global_'..name)
end
function Data:get_track_val(track,name) 
	return params:get(name..'_t'..track) 
end
function Data:get_page_val(track,page,name) 
	local param_string = name..'_'..page..'_t'..track
	if tab.contains({'loop_first','loop_last','divisor'},name) then
		param_string = param_string..'_p'..self.pattern
	end
	return params:get(param_string)
end
function Data:get_step_val(track,page,step) 
	return params:get('data_'..page..'_'..step..'_t'..track..'_p'..self.pattern) 
end

-- SET
function Data:set_global_val(name,new_val)
	params:set('global_'..name,new_val)
end
function Data:set_track_val(track,name,new_val) 
	params:set(name..'_t'..track,new_val) 
end
function Data:set_page_val(track,page,name,new_val) 
	local param_string = name..'_'..page..'_t'..track
	if tab.contains({'loop_first','loop_last','divisor'},name) then
		param_string = param_string..'_p'..self.pattern
	end
	return params:set(param_string,new_val)
end
function Data:set_step_val(track,page,step,new_val) 
	params:set('data_'..page..'_'..step..'_t'..track..'_p'..self.pattern,new_val) 
end

-- DELTA
function Data:delta_global_val(name,d)
	params:delta('global_'..name,d)
end
function Data:delta_track_val(track,name,d) 
	params:delta(name..'_t'..track,d) 
end
function Data:delta_page_val(track,page,name,d) 
	local param_string = name..'_'..page..'_t'..track
	if tab.contains({'loop_first','loop_last','divisor'},name) then
		param_string = param_string..'_p'..self.pattern
	end
	return params:delta(param_string,d)
end
function Data:delta_step_val(track,page,step,d) 
	params:delta('data_'..page..'_'..step..'_t'..track..'_p'..self.pattern,d) 
end

function Data:get_subtrig(track,step,subtrig)
	return params:get('data_subtrig_'..subtrig..'_step_'..step..'_t'..track..'_p'..self.pattern)
end
function Data:set_subtrig(track,step,subtrig,one_or_zero)
	params:set('data_subtrig_'..subtrig..'_step_'..step..'_t'..track..'_p'..self.pattern, one_or_zero)
end

return Data
