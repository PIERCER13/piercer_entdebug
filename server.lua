-- Records every entity the server sees being created and removed, so you can look up the ids printed by
--   script error in native 00000000xxxxxxxx: Tried to access invalid entity: <id>
-- and find out what they were (or whether the server ever knew them at all).

-- Commands (server console, or players with the ACE "command.<name>"):
--   entinfo <id> [id ...]   what those entities were
--   entlast [n]             last n removed entities (default 20)
--   entstats                how many entities are being tracked
--   entclear                forget everything recorded so far

-- Convars (set before ensure, in server.cfg):
--   set entdebug_keep_minutes 30      how long a removed entity stays in memory
--   set entdebug_track_created true   also record entities on creation (needed for "still exists")

local KEEP_SECONDS = math.max(1, GetConvarInt('entdebug_keep_minutes', 30)) * 60
local TRACK_CREATED = GetConvar('entdebug_track_created', 'true') ~= 'false'

local removed = {}   -- [handle] = snapshot taken when the server removed it
local order = {}     -- removed handles, oldest first (for entlast)
local created = {}   -- [handle] = snapshot taken when the server created it
local startedAt = os.time()

local TYPES = { [0] = 'none', [1] = 'PED', [2] = 'VEHICLE', [3] = 'OBJECT' }
local POP = {
    [0] = 'unknown', [1] = 'random_permanent', [2] = 'random_parked', [3] = 'random_patrol',
    [4] = 'random_scenario', [5] = 'random_ambient', [6] = 'permanent', [7] = 'mission',
    [8] = 'replay', [9] = 'cache', [10] = 'tool'
}


-- HELPERS
local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then return res end
end

local function playerLabel(src)
    if not src or src <= 0 then return '-' end
    local name = GetPlayerName(src)
    return name and ('%d (%s)'):format(src, name) or tostring(src)
end

local function snapshot(entity)
    local etype = safe(GetEntityType, entity) or 0
    local coords = safe(GetEntityCoords, entity)
    local heading = safe(GetEntityHeading, entity)
    local pop = safe(GetEntityPopulationType, entity)

    return {
        time = os.time(),
        handle = entity,
        netid = safe(NetworkGetNetworkIdFromEntity, entity),
        type = TYPES[etype] or tostring(etype),
        model = safe(GetEntityModel, entity),
        pop = pop and (POP[pop] or tostring(pop)) or '?',
        creator = playerLabel(safe(NetworkGetFirstEntityOwner, entity)),
        owner = playerLabel(safe(NetworkGetEntityOwner, entity)),
        coords = coords and ('%.1f, %.1f, %.1f'):format(coords.x, coords.y, coords.z) or '?',
        heading = heading and ('%.1f'):format(heading) or '?',
    }
end

local function describe(info)
    return ('[%s] ent=%d netid=%s type=%s model=%s pop=%s creator=%s owner=%s coords=%s heading=%s'):format(
        os.date('%H:%M:%S', info.time), info.handle, tostring(info.netid), info.type, tostring(info.model),
        info.pop, info.creator, info.owner, info.coords, info.heading
    )
end

-- prints to the server console, or to the player's chat when run in game
local function reply(source, msg)
    if source == 0 then
        print(msg)
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '^3entdebug', msg } })
    end
end

-- TRACKING
if TRACK_CREATED then
    AddEventHandler('entityCreated', function(entity)
        -- model/owner are not always readable in the same tick the event fires
        SetTimeout(0, function()
            if DoesEntityExist(entity) then
                created[entity] = snapshot(entity)
            end
        end)
    end)
end

AddEventHandler('entityRemoved', function(entity)
    removed[entity] = snapshot(entity)
    created[entity] = nil
    order[#order + 1] = entity
end)

CreateThread(function()
    while true do
        Wait(60000)

        local limit = os.time() - KEEP_SECONDS
        local newOrder = {}
        for _, h in ipairs(order) do
            local info = removed[h]
            if info and info.time >= limit then
                newOrder[#newOrder + 1] = h
            elseif info then
                removed[h] = nil
            end
        end
        order = newOrder

        for h in pairs(created) do
            if not DoesEntityExist(h) then created[h] = nil end
        end
    end
end)


-- COMMANDS
RegisterCommand('entinfo', function(source, args)
    if #args == 0 then return reply(source, 'usage: entinfo <id> [id ...]') end

    local counts, keys = {}, {}
    local function count(key)
        if not counts[key] then keys[#keys + 1] = key end
        counts[key] = (counts[key] or 0) + 1
    end

    for _, a in ipairs(args) do
        local h = tonumber(a)
        if h and h ~= math.floor(h) then h = nil end
        local info = h and removed[h]
        if not h then
            reply(source, ('"%s" is not a number. Use the ids from the error, e.g. entinfo 132353 141074'):format(a))
        elseif info then
            reply(source, 'REMOVED ' .. describe(info))
            count('removed: ' .. info.type .. ' / ' .. info.pop .. ' / model ' .. tostring(info.model))
        elseif safe(DoesEntityExist, h) then
            reply(source, 'STILL EXISTS ' .. describe(created[h] or snapshot(h)))
            count('still exists')
        else
            reply(source, ('ent=%d -> the server NEVER saw this entity (tracking for %d min)'):format(h, (os.time() - startedAt) // 60))
            count('never existed on the server (most likely a CLIENT handle sent to the server)')
        end
    end

    if #keys > 0 then
        reply(source, '--- summary ---')
        for _, k in ipairs(keys) do reply(source, ('%dx  %s'):format(counts[k], k)) end
    end
end, true)

RegisterCommand('entlast', function(source, args)
    local n = tonumber(args[1]) or 20
    if #order == 0 then return reply(source, 'no entity removed yet') end
    for i = math.max(1, #order - n + 1), #order do
        local info = removed[order[i]]
        if info then reply(source, describe(info)) end
    end
end, true)

RegisterCommand('entstats', function(source)
    local alive = 0
    for _ in pairs(created) do alive = alive + 1 end
    reply(source, ('tracking for %d min | removed in memory: %d (kept %d min) | created tracked: %s'):format(
        (os.time() - startedAt) // 60, #order, KEEP_SECONDS // 60, TRACK_CREATED and tostring(alive) or 'disabled'
    ))
end, true)

RegisterCommand('entclear', function(source)
    removed, order, created = {}, {}, {}
    startedAt = os.time()
    reply(source, 'cleared')
end, true)

print(('^2[piercer_entdebug]^7 running (keep %d min, track created: %s). Use "entinfo <ids>" after the error shows up.'):format(
    KEEP_SECONDS // 60, tostring(TRACK_CREATED)
))
