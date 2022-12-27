nb = require("k2z/lib/nb/nb")

function add_midi_players()
    for i, v in ipairs(midi.vports) do
        if v.connected then
            local conn = midi.connect(i)
            local player = {
                conn = conn
            }
            function player:add_params()
                params:add_group("midi_voice_"..i, "midi: "..v.name, 1)
                params:add_number("midi_chan_"..i, "channel", 1, 16)
            end
            function player:note_on(note, vel)
                self.conn:note_on(note, util.clamp(math.floor(127*vel), 0, 127))
            end
            function player:note_off(note)
                self.conn:note_off(note)
            end
            function player:active()
                params:show("midi_voice_"..i)
                _menu.rebuild_params()
            end
            function player:inactive()
                params:hide("midi_voice_"..i)
                _menu.rebuild_params()
            end
            nb.players[v.name] = player
        end
    end
end