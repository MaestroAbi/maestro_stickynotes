local markers = {}
local targetZones = {}
local noteProps = {}

-- Initialize notes from server
RegisterNetEvent('maestro_stickynotes:initNotes', function(notes)
    markers = {}
    for noteId, note in pairs(notes) do
        markers[noteId] = note
        addTargetZone(noteId, note.coords)

        -- Spawn sticky note prop again
        if not noteProps[noteId] then
            local prop = CreateObject(`xs_prop_arena_stickynote_01a`, note.coords.x, note.coords.y, note.coords.z - 0.01, false, true, false)

            -- Set proper rotation
            SetEntityRotation(prop, 0, 0, GetEntityHeading(PlayerPedId()), 2, true)

            -- Adjust placement slightly away from the wall
            local forwardOffset = 0.02
            local heading = GetEntityHeading(PlayerPedId())
            local radHeading = math.rad(heading)
            local offsetX = math.cos(radHeading) * forwardOffset
            local offsetY = math.sin(radHeading) * forwardOffset

            SetEntityCoords(prop, note.coords.x + offsetX, note.coords.y + offsetY, note.coords.z - 0.01)

            SetEntityCollision(prop, false, false) -- Disable collision
            --FreezeEntityPosition(prop, true) -- Prevent movement

            noteProps[noteId] = prop
        end
    end
end)

-- Add single note
RegisterNetEvent('maestro_stickynotes:addNote', function(noteId, coords, header, text)
    markers[noteId] = {
        coords = coords,
        header = header,
        text = text
    }
    addTargetZone(noteId, coords)

    -- Spawn sticky note prop at coords (slightly lowered to prevent floating)
    local prop = CreateObject(`xs_prop_arena_stickynote_01a`, coords.x, coords.y, coords.z - 0.02, false, true, false)

    -- Ensure the entity exists before proceeding
    if not DoesEntityExist(prop) then
        print("Error: Failed to spawn sticky note prop")
        return
    end

    -- Get prop dimensions
    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop))
    local propHeight = maxDim.z - minDim.z -- Total height of the prop

    -- Get surface normal to determine placement correction
    local normalX, normalY, normalZ = surfaceNormal.x, surfaceNormal.y, surfaceNormal.z

    -- Adjust forward position (prevents clipping into walls)
    local forwardOffset = 0.02-- Move slightly away from walls
    local newX = coords.x + (normalX * forwardOffset)
    local newY = coords.y + (normalY * forwardOffset)

    -- If placed on a wall, adjust height slightly so it's **not too high**
    local newZ = (math.abs(normalZ) > 0.9) and (coords.z - 0.02) or (coords.z - propHeight / 2)

    -- Set corrected position
    SetEntityCoords(prop, newX, newY, newZ, false, false, false, false)

    -- Determine correct rotation
    if math.abs(normalZ) > 0.9 then
        -- If placed on ground/ceiling, align with player's heading
        SetEntityRotation(prop, 0, 0, GetEntityHeading(PlayerPedId()), 2, true)
    else
        -- If placed on a wall, rotate correctly to align with the surface
        local pitch = math.deg(math.asin(normalZ))
        local yaw = math.deg(math.atan(normalX, -normalY))
        SetEntityRotation(prop, pitch, 0, yaw, 2, true)
    end

    -- Disable collision & freeze
    SetEntityCollision(prop, false, false)
    -- FreezeEntityPosition(prop, true)

    -- Store prop reference
    noteProps[noteId] = prop
end)

-- Remove note
RegisterNetEvent('maestro_stickynotes:removeNote', function(noteId)
    if not markers[noteId] then return end

    -- Remove ox_target zone
    if targetZones[noteId] then
        exports.ox_target:removeZone(targetZones[noteId])
        targetZones[noteId] = nil
    end

    -- Remove sticky note prop
    if noteProps[noteId] then
        if DoesEntityExist(noteProps[noteId]) then
            DeleteEntity(noteProps[noteId])
        end
        noteProps[noteId] = nil
    end

    -- Remove from client markers
    markers[noteId] = nil
end)

-- Target zone management
function addTargetZone(noteId, coords)
    if targetZones[noteId] then return end

    targetZones[noteId] = exports.ox_target:addSphereZone({
        coords = coords,
        radius = 0.3,
        debug = false,
        options = {
            {
                name = 'read_sticky_'..noteId,
                label = 'Read Note',
                icon = 'fas fa-note-sticky',
                onSelect = function()
                    lib.alertDialog({
                        header = markers[noteId].header,  -- Use stored header
                        content = markers[noteId].text,
                        centered = true
                    })
                end
            },
            {
                name = 'take_sticky_'..noteId,
                label = 'Take Note',
                icon = 'fas fa-hand',
                onSelect = function()
                    if lib.progressBar({
                        duration = 2000,
                        label = 'Removing note',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            car = true,
                            move = true,
                            combat = true,
                            mouse = false
                        },
                        anim = {
                            dict = 'anim@narcotics@trash',
                            clip = 'drop_front'
                        }
                    }) then
                        TriggerServerEvent('maestro_stickynotes:removeNote', noteId)
                    else
                        exports.ox_lib:notify({ title = 'Error', description = 'Failed to take', type = 'error' })
                    end
                end
            }
        }
    })
end

local isPlacing = false

local function useItem()
    TriggerEvent('maestro_stickynotes:startPlacement')
end

exports('useItem', useItem)

RegisterNetEvent('maestro_stickynotes:startPlacement', function()
    if isPlacing then return end
    isPlacing = true

    lib.showTextUI('Aim where to place the note and press [E]', {
        position = 'top-center',
        icon = 'fas fa-note-sticky'
    })

    CreateThread(function()
        while isPlacing do
            -- Perform raycast from the camera
            local hit, coords = performRaycast()

            if hit then
                -- Visual feedback: Draw a marker at the hit location
                DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.05, 0.05, 0.05, 255, 42, 24, 100, false, true, 2, nil, nil, false)

                if IsControlJustPressed(0, 38) then -- E key
                    isPlacing = false
                    lib.hideTextUI()

                    -- Modified input dialog with header field
                    local input = lib.inputDialog('Create Sticky Note', {
                        {type = 'input', label = 'Note Header', placeholder = 'Important Note', required = true, min = 1, max = 50},
                        {type = 'textarea', label = 'Note Content', required = true, min = 1, max = 500}
                    })

                    if input and input[1] and input[2] then
                        local noteId = generateUUID()
                        markers[noteId] = {
                            coords = coords,
                            header = input[1],  -- Store header
                            text = input[2]     -- Store content
                        }
                        -- Ensure surfaceNormal is sent
                        if not surfaceNormal then
                            surfaceNormal = vector3(0, 0, 1) -- Default to ground if normal is nil
                        end

                        -- Pass surfaceNormal to the server
                        if lib.progressBar({
                            duration = 2000,
                            label = 'placing note',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true,
                                combat = true,
                                mouse = false
                            },
                            anim = {
                                dict = 'anim@narcotics@trash',
                                clip = 'drop_front'
                            }
                        }) then
                            TriggerServerEvent('maestro_stickynotes:placeNote', noteId, coords, input[1], input[2], surfaceNormal)
                            addTargetZone(noteId, coords)
                        else
                            exports.ox_lib:notify({ title = 'Error', description = 'Failed to take', type = 'error' })
                        end
                    end
                end
            else
                lib.showTextUI('No valid surface found. Aim at a valid surface to place the note.', {
                    position = 'top-center',
                    icon = 'fas fa-exclamation-triangle'
                })
            end
            Wait(0)
        end
    end)
end)

function performRaycast()
    local cameraRotation = GetGameplayCamRot(2)
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = cameraCoord + direction * 25.0

    local rayHandle = StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, 1 | 4 | 8 | 16, -1, 0)
    local _, hit, endCoords, surfaceNormal, _ = GetShapeTestResult(rayHandle)

    return hit, endCoords, surfaceNormal
end

function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end

function generateUUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
        return string.format('%x', v)
    end)
end