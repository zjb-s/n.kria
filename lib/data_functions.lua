--[[
WHAT GOES IN THIS FILE:
- this is a table that contains methods
- these methods get and set information from 'data' params
- `Data.pattern` controls which pattern data methods will address. usually you don't need to change it.
]]--

local Data = {}

Data.pattern = 1

function Data:get_track_val(track,name) return params:get(name..'_t'..track) end
function Data:get_page_val(track,page,name) return params:get(name..'_'..page..'_t'..track..'_p'..self.pattern) end
function Data:get_step_val(track,page,step) return params:get('data_'..page..'_'..step..'_t'..track..'_p'..self.pattern) end
function Data:set_track_val(track,name,new_val) params:set(name..'_t'..track,new_val) end
function Data:set_page_val(track,page,name,new_val) params:set(name..'_'..page..'_t'..track..'_p'..self.pattern,new_val) end
function Data:set_step_val(track,page,step,new_val) params:set('data_'..page..'_'..step..'_t'..track..'_p'..self.pattern,new_val) end
function Data:delta_track_val(track,name,d) params:delta(name..'_t'..track,d) end
function Data:delta_page_val(track,page,name,d) params:delta(name..'_'..page..'_t'..track..'_p'..self.pattern,d) end
function Data:delta_step_val(track,page,step,d) params:delta('data_'..page..'_'..step..'_t'..track..'_p'..self.pattern,d) end

-- above has no support for probability or subtrigs
-- use below for getting or setting those params

function Data:get_unique(track,page,step,aux)
	if page == 'subtrig' then
		return params:get('data_subtrig_'..aux..'_step_'..step..'_t'..track..'_p'..self.pattern) == 1
	elseif page == 'subtrig_count' then
		return params:get('data_subtrig_count_'..step..'_t'..track..'_p'..self.pattern)
	elseif string.sub(page,-4,-1) == 'prob' then
		return params:get('data_'..page..'_'..step..'_t'..track..'_p'..self.pattern)
	end
end

function Data:set_unique(track,page,step,aux,aux2)
	if page == 'subtrig' then
		params:set('data_subtrig_'..aux..'_step_'..step..'_t'..track..'_p'..self.pattern,aux2 and 1 or 0)
	elseif page == 'subtrig_count' then
		params:set('data_subtrig_count_'..step..'_t'..track..'_p'..self.pattern,aux)
	elseif string.sub(page,-4,-1) == 'prob' then
		print('setting prob to',aux)
		params:set('data_'..page..'_'..step..'_t'..track..'_p'..self.pattern,aux)
	end
end

function Data:delta_unique(track,page,step,aux,aux2)
	if page == 'subtrig' then
		self:set_unique(track,'subtrig',step,aux, not self:get_unique(track,'subtrig',step,aux))
	elseif page == 'subtrig_count' then
		self:set_unique(track,'subtrig_count',step,aux+self:get_unique(track,'subtrig_count',step))
	elseif string.sub(page,-4,-1) == 'prob' then
		self:set_unique(track,'prob',step,aux+self:get_unique(track,'prob',step))
	end
end

return Data