local player_lib = require "k2z/lib/nb/player"

local nb = {}

if note_players == nil then
    note_players = {}
end

nb.players = note_players -- alias the global here. Helps with standalone use.

nb.none = player_lib:new()

function nb:init()
    refcounts = {}
end

function nb:add_param(param_id, param_name)
    local names = {}
    for name, _ in pairs(note_players) do
        table.insert(names, name)
    end
    table.sort(names)
    table.insert(names, 1, "none")
    params:add_option(param_id, param_name, names, 1)
    local p = params:lookup_param(param_id)
    function p:get_player()
        local i = p:get()
        local name = names[i]
        if name == "none" then
            if p.player ~= nil then
                p.player:count_down()
            end
            p.player = nil
            return nb.none
        elseif p.player ~= nil and p.player.name == name then
            return p.player
        else
            if p.player ~= nil then
                p.player:count_down()
            end
            local ret = player_lib:new(nb.players[name])
            ret.name = name
            p.player = ret
            ret:count_up()
            return ret
        end
    end
    clock.run(function()
        clock.sleep(1)
        p:get_player()
    end, p)
    params:set_action(param_id, function()
        p:get_player()
    end)
end

return nb