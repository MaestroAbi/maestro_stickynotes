local STICKYNOTES = {}

-- Load notes from database
MySQL.ready(function()
    local notes = MySQL.query.await('SELECT * FROM player_stickynotes')
    STICKYNOTES = {}
    if notes then
        for _, note in ipairs(notes) do
            STICKYNOTES[note.id] = {
                coords = json.decode(note.coords),
                header = note.header,
                text = note.text
            }
        end
        print('[StickyNotes] Loaded', #notes, 'notes')
    end
end)

-- Send notes to players when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent('maestro_stickynotes:initNotes', playerId, STICKYNOTES)
    end
end)

-- Handle new players
AddEventHandler('playerJoining', function()
    TriggerClientEvent('maestro_stickynotes:initNotes', source, STICKYNOTES)
end)

-- Place note
RegisterNetEvent('maestro_stickynotes:placeNote', function(noteId, coords, header, text)
    STICKYNOTES[noteId] = {
        coords = coords,
        header = header,  -- Store header
        text = text
    }

    exports.ox_inventory:RemoveItem(source, 'stickynote', 1)

    MySQL.query.await('INSERT INTO player_stickynotes (id, coords, header, text) VALUES (?, ?, ?, ?)', {
        noteId,
        json.encode(coords),
        header,
        text
    })

    -- Send surfaceNormal to client for correct orientation
    TriggerClientEvent('maestro_stickynotes:addNote', -1, noteId, coords, header, text, surfaceNormal)
end)

-- Remove note
RegisterNetEvent('maestro_stickynotes:removeNote', function(noteId)
    if STICKYNOTES[noteId] then
        STICKYNOTES[noteId] = nil
        MySQL.query('DELETE FROM player_stickynotes WHERE id = ?', { noteId })

        -- Send removal to all clients
        TriggerClientEvent('maestro_stickynotes:removeNote', -1, noteId)

        -- Give back the sticky note item
        exports.ox_inventory:AddItem(source, 'stickynote', 1)
    end
end)