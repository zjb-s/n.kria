local bit32 = require('bit32')
local tab = require('tabutil')

local Rewriter = {}

function Rewriter.rewrite(filename)
    local result = {}

    for line in io.lines(filename) do
        for s, t, p, v in string.gmatch(line, '.([%w_]*)_t(%d*)_p(%d*).: (%d*)') do
            p = tonumber(p)
            v = tonumber(v)
            t = tonumber(t)
            local pattern = result[p]
            if pattern == nil then
                pattern = {}
                result[p] = pattern
            end
            local track = pattern[t]
            if track == nil then
                track = {}
                pattern[t] = track
            end
            local was_step = false
            local was_subtrig = false
            for st, step in string.gmatch(s, "data_subtrig_(%d+)_step_(%d+)") do
                st = tonumber(st)
                step = tonumber(step)
                was_subtrig = true
                local page = "retrig"
                local thing = "subtrig"
                if not track[page] then track[page] = {} end
                if not track[page][step] then track[page][step] = {} end
                local value = track[page][step][thing]
                if not value then
                    value = 0
                end
                value = bit32.replace(value, v, st - 1)
                track[page][step][thing] = value
            end
            if not was_subtrig then
                for page, thing, step in string.gmatch(s, "data_(%w*)_(%a*)_?(%d+)") do
                    -- print("pat", p, "track", t, "page", page, "step", step, thing, "is", v)
                    step = tonumber(step)
                    was_step = true
                    if thing == "" then
                        thing = "step"
                    end
                    if not track[page] then track[page] = {} end
                    if not track[page][step] then track[page][step] = {} end
                    track[page][step][thing] = v
                end
            end
            if not was_subtrig and not was_step then
                for thing, page in string.gmatch(s, "([%w_]*)_(%a+)") do
                    if not track[page] then track[page] = {} end
                    track[page][thing] = v
                end
                -- print(s, t, p, v)
            end
        end
    end
    tab.save(result, filename .. ".kriapattern")
end


return Rewriter