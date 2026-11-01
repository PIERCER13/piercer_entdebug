# piercer_entdebug

> Find out what is behind `Tried to access invalid entity` errors on your FiveM server.

🇧🇷 [Leia em português](README.pt-BR.md) · 💬 [FrameZero Discord](https://discord.gg/jZ3vTmdjU7)

```
[    c-scripting-core] script error in native 00000000dafcb3ec: Tried to access invalid entity: 132353
[    c-scripting-core] script error in native 00000000972cc383: Tried to access invalid entity: 132353
```

If your console looks like this, you know *something* is calling a native on an entity that doesn't exist. But the log doesn't say **which resource**, **which entity**, or **why**. Obfuscated and escrowed resources make it worse: you can't even grep for the culprit.

**piercer_entdebug** records every entity the server sees being created and removed. When the error shows up, you paste the ids and it tells you what each entity was, or that the server **never knew it at all**.

- Runs on any framework through **framezero_bridge** (vRP, vRPex, ESX, QBCore, Qbox, Creative or standalone) — it is a hard dependency.
- Server-side only. It answers only the players who run a command.
- Zero cost when idle: it only reacts to `entityCreated` / `entityRemoved`.
- Read-only. It never changes or deletes entities.

---

## Installation

1. Download or clone **both** repositories into your `resources` folder:
   ```
   resources/framezero_bridge
   resources/piercer_entdebug
   ```
   `framezero_bridge` is mandatory: it handles the permission check (framework group/job/ACE) and the in-game notification. FiveM starts it first, because of the `dependency` in the manifest.
2. Start it from the server console (no need to add it to `server.cfg`, it's a debugging tool):
   ```
   refresh
   ensure piercer_entdebug
   ```
3. You should see:
   ```
   [piercer_entdebug] running (keep 30 min, track created: true). Use "entinfo <ids>" after the error shows up.
   ```

> Start it **before** the error happens. Entities removed before the resource started cannot be looked up.

---

## Commands

| Command | Description |
|---|---|
| `entinfo <id> [id ...]` | Shows what each entity was, plus a grouped summary. Use the numbers at the end of the error lines. |
| `entlast [n]` | Lists the last `n` removed entities (default `20`). Useful to see what was vanishing when the error happened. |
| `entstats` | How long it has been tracking and how many entities are in memory. |
| `entclear` | Forgets everything recorded so far and restarts the clock. |

All commands work in the **server console** (txAdmin Live Console or the FXServer window). To use them in game, allow the player through the framework (via `framezero_bridge`) or through an ACE:

```lua
-- config.lua
Config.perms = { 'admin' }  -- ESX group / QBCore-Qbox job, gang, permission / vRP group / ACE (standalone)
```

```cfg
-- or, without touching the config:
add_ace group.admin command.entinfo allow   # one command
add_ace group.admin command.entlast allow
add_ace group.admin entdebug.admin allow    # all of them at once
```

In game, the output goes to the chat (or to a notification, when the server has no `chat` resource).

---

## Configuration

Optional convars. Set them in `server.cfg` **before** `ensure piercer_entdebug`:

| Convar | Default | Description |
|---|---|---|
| `entdebug_keep_minutes` | `30` | How long a removed entity stays in memory. |
| `entdebug_track_created` | `true` | Also record entities when they are created (needed for the *STILL EXISTS* result). |

```cfg
set entdebug_keep_minutes 60
set entdebug_track_created true
```

### Permissions

Who can run the commands in game is set in `config.lua` (the server console is always allowed):

| Config | Default | Description |
|---|---|---|
| `Config.perms` | `{ 'admin' }` | Permissions checked through `framezero_bridge`. Empty = only the ACEs above apply. |
| `Config.denied` | `you don't have access to this.` | Message sent to a player without permission. |

---

## Usage

1. `ensure piercer_entdebug`
2. Wait for the error to appear again.
3. Copy the **number at the end** of the new error lines (the `<id>` in `Tried to access invalid entity: <id>`).
4. Run:
   ```
   entinfo 154872 160233 139981
   ```

### Reading the result

**`REMOVED`**: it was a real entity and it was deleted.

```
REMOVED [21:14:03] ent=154872 netid=23800 type=VEHICLE model=-1216765807 pop=mission creator=3 (John) owner=3 (John) coords=215.3, -810.1, 30.7 heading=158.2
```

Some script stored this entity and kept using it after it was deleted. The `type`, `model`, `creator` and `coords` tell you which system it belongs to. For example, a vehicle at the garage spawn point points to the garage script. **Fix:** check `DoesEntityExist(entity)` before using a stored entity, and clean up your references on `entityRemoved`.

**`STILL EXISTS`**: the entity is valid right now. The call probably happened during creation or migration. This is rare.

**`the server NEVER saw this entity`**: this is the most common case, and the most useful one.

```
ent=139981 -> the server NEVER saw this entity (tracking for 12 min)
--- summary ---
3x  never existed on the server (most likely a CLIENT handle sent to the server)
```

A **client** entity handle (from `PlayerPedId()`, `GetVehiclePedIsIn()`, `GetClosestVehicle()`...) only means something **on that player's game**. Some script is sending it to the server through an event or callback, and the server is calling natives on a number that means nothing there.

---

## Fixing "client handle sent to the server"

Look for client code that sends a raw entity in an event:

```lua
-- ❌ client: sends the local handle
local veh = GetVehiclePedIsIn(PlayerPedId(), false)
TriggerServerEvent('myscript:saveVehicle', veh)

-- ❌ server: uses it as if it were a server entity
RegisterNetEvent('myscript:saveVehicle', function(veh)
    local model = GetEntityModel(veh)      -- Tried to access invalid entity
    local heading = GetEntityHeading(veh)  -- Tried to access invalid entity
end)
```

Send the **network id** and convert it on the server:

```lua
-- ✅ client
local veh = GetVehiclePedIsIn(PlayerPedId(), false)
TriggerServerEvent('myscript:saveVehicle', NetworkGetNetworkIdFromEntity(veh)) -- or VehToNet(veh)

-- ✅ server
RegisterNetEvent('myscript:saveVehicle', function(netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    local model = GetEntityModel(veh)
    local heading = GetEntityHeading(veh)
end)
```

> If the entity is not networked (created locally with `isNetwork = false`), the server can't see it at all. Send the data you need (model, coords, heading) instead of the entity.

**Tips for finding the culprit:**
- Search your resources for `TriggerServerEvent`, `TriggerCallback`, `lib.callback`, `vRP` tunnels, etc. whose arguments include `PlayerPedId()`, `GetVehiclePedIsIn`, `GetClosestVehicle`, `GetClosestObject` or similar variables.
- The pair of natives in the error tells you what the server does with the entity (see the table below). For example, *model + heading* usually means "save this vehicle/ped position".
- If the culprit is obfuscated or escrowed, stop candidate resources one at a time and watch whether the error stops.

---

## Native hash reference

The error prints the **hash** of the native, not its name. These are common server natives:

| Hash | Native |
|---|---|
| `0xDAFCB3EC` | `GetEntityModel` |
| `0x972CC383` | `GetEntityHeading` |
| `0x1647F1CB` | `GetEntityCoords` |
| `0x0B1BD08D` | `GetEntityType` |
| `0x8FF45B04` | `GetEntityRotation` |
| `0xC14C9B6B` | `GetEntityVelocity` |
| `0x8E3222B7` | `GetEntityHealth` |
| `0xFC30DDFF` | `GetEntityPopulationType` |
| `0xED4B0486` | `GetEntityRoutingBucket` |
| `0x635E5289` | `SetEntityRoutingBucket` |
| `0xE8522D58` | `GetVehicleNumberPlateText` |
| `0x388FDE9A` | `GetPedInVehicleSeat` |
| `0xAFE92319` | `GetVehiclePedIsIn` |
| `0xD240123E` | `GetSelectedPedWeapon` |
| `0x9E35DAB6` | `NetworkGetNetworkIdFromEntity` |
| `0x526FEE31` | `NetworkGetEntityOwner` |
| `0xDF70B41B` | `SetEntityCoords` |
| `0xE0FF064D` | `SetEntityHeading` |
| `0x65C16D57` | `FreezeEntityPosition` |
| `0xFAA3D236` | `DeleteEntity` |

Not in the list? Your server build has all of them. Open `citizen/scripting/v8/natives_server.js` in your FXServer folder and search for the hash in lowercase (e.g. `0xdafcb3ec`).

---

## FAQ

**Does it affect performance?**
No noticeable impact. It stores a small table per entity and cleans it every minute. Removed entities expire after `entdebug_keep_minutes`.

**Should I leave it running forever?**
It's meant for debugging. Start it, find the problem, then `stop piercer_entdebug`.

**Why doesn't the error show the resource name?**
When the calling script catches the error (`pcall`, `try/catch`), only the `c-scripting-core` line is printed, with no stack trace. That's exactly the case this tool was made for.

**Does it work with OneSync?**
Yes. It requires OneSync, like any server-side entity code.

---

## Support & community

Found a bug, have an idea, or need help reading the output?

- 💬 **FrameZero Discord:** [discord.gg/jZ3vTmdjU7](https://discord.gg/jZ3vTmdjU7)
- 👤 **Author:** `@piercer` on Discord

Pull requests are welcome.

---

## License

[MIT](LICENSE) © PIERCER / FrameZero. Use, modify and share freely. A ⭐ on the repository is appreciated.
