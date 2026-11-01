<div align="center">

# 🔍 piercer_entdebug

**Find out what is really behind the `Tried to access invalid entity` errors on your FiveM server.**

An entity detective that runs on **any framework**: it records everything the server sees being created and
removed, and when the error shows up it tells you what each id was — or that the server **never knew** that
entity at all. No guessing, no blind grep.

![FiveM](https://img.shields.io/badge/FiveM-resource-F40552?style=for-the-badge)
![Frameworks](https://img.shields.io/badge/ESX%20%C2%B7%20QBCore%20%C2%B7%20Qbox%20%C2%B7%20vRP%20%C2%B7%20standalone-2b2b2b?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-5.4-000080?style=for-the-badge&logo=lua&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-22c55e?style=for-the-badge)
[![Discord](https://img.shields.io/badge/Discord-join-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/jZ3vTmdjU7)

🇧🇷 [Leia em português](README.pt-BR.md)

</div>

---

## 🎯 What it is for

If your server console looks like this, you already know the problem:

```
[    c-scripting-core] script error in native 00000000dafcb3ec: Tried to access invalid entity: 132353
[    c-scripting-core] script error in native 00000000972cc383: Tried to access invalid entity: 132353
```

Something is calling a native on an entity that **no longer exists** (or that never existed on the server
side). The catch: the log does not tell **which resource** did it, **what the entity was**, or **why**.
Obfuscated and escrowed resources make it worse — you can't even grep for the culprit.

**piercer_entdebug** records every entity the server sees being created and removed. When the error shows up,
you paste the ids and it tells you what each one was, or that the server **never knew** that number at all.

| Situation | What you get |
|---|---|
| ❌ Without entdebug | `Tried to access invalid entity: 132353` … and nothing else |
| ✅ With entdebug | `REMOVED [21:14:03] ent=132353 netid=23800 type=VEHICLE model=-1216765807 …` |

> 💡 The id in the error changes for every entity. Save **all** the numbers from the error lines: running `entinfo` with several ids groups the results at the end.

## 🔧 How it works

1. **The server records**: `server.lua` listens to `entityCreated` and `entityRemoved` and keeps a snapshot of each entity — type, model, network id, owner, creator, coords, heading and population type.
2. **Memory cleans itself**: every minute it forgets whatever is older than `entdebug_keep_minutes` (default: 30). Entities that are still alive are dropped from the record when they stop existing.
3. **You ask**: run `entinfo <ids>` in the console (or in game, with permission) using the numbers from the error.
4. **It answers**: `REMOVED`, `STILL EXISTS` or `the server NEVER saw this entity`, each with a full detail line plus a grouped summary at the end.
5. **The answer lands where it should**: the console gets the log; in game it goes to the chat (or to a [framezero_bridge](https://github.com/PIERCER13/framezero_bridge) notification, if the server has no `chat` resource).

```
entityCreated ──▶ snapshot ──▶ created[]
entityRemoved ──▶ snapshot ──▶ removed[]
                                 │
                     entinfo <ids>
                                 │
                                 ▼
                 REMOVED · STILL EXISTS · NEVER SAW
```

> 🧩 Permission and notification are handled by **framezero_bridge** (ESX, QBCore, Qbox, vRP, vRPex, Creative or standalone). `piercer_entdebug` is only the investigation part.

## ✨ What it does

- 🔎 **Tells you what each id was** from the error: type, model, netid, creator, owner, coords and heading.
- 🧠 **Detects when the server never saw the entity** — the most common (and most useful) case: a client handle sent to the server.
- 🧩 **Multi-framework** through framezero_bridge, without changing a single line of code.
- 🖥️ **Works in the console and in game** (with permission), with the same output.
- 📋 **Grouped summary** at the end of `entinfo`, so you immediately see how many ids fell into each case.
- 💤 **Zero cost when idle**: it only reacts to `entityCreated` / `entityRemoved`, no heavy loops.
- 🔒 **Read-only**: it never changes, moves or deletes entities.
- 🧹 **Controlled memory**: configurable retention and automatic cleanup.
- ⏱️ **`entlast`** shows what was vanishing at the exact moment of the error.
- 📦 **No mandatory configuration**: drop it in, `ensure` it, done.

## 📋 Requirements

| Requirement | Note |
|---|---|
| **FiveM** server | Any recent artifact |
| **OneSync** | Required, like any server-side entity code |
| **[framezero_bridge](https://github.com/PIERCER13/framezero_bridge)** | Hard dependency: it handles permission and notification. The manifest `dependency` makes it start first |
| **`chat`** resource | Optional. Without it, in-game replies use the bridge notification |

## 🚀 Installation

1. Install **framezero_bridge** into `resources/`. The folder must be named exactly `framezero_bridge`.
2. Download this repository (**Code › Download ZIP**) or clone it:
   ```bash
   git clone https://github.com/PIERCER13/piercer_entdebug.git
   ```
3. Put the `piercer_entdebug` folder into your server's `resources/`.
4. Add it to `server.cfg` in the order **framework → bridge → entdebug**:
   ```cfg
   ensure vrp              # or es_extended, qb-core, qbx_core... (skip if standalone)
   ensure framezero_bridge
   ensure piercer_entdebug
   ```
5. Start the server. You should see:
   ```
   [piercer_entdebug] running (keep 30 min, track created: true). Use "entinfo <ids>" after the error shows up.
   ```

> ⚠️ It is a debugging tool: you can start it only when you need it (`ensure piercer_entdebug` in the console) instead of leaving it in `server.cfg` forever.

## 🎬 Quick start

1. `ensure piercer_entdebug`
2. Wait for the error to show up again.
3. Copy the **number at the end** of the new lines (the `<id>` in `Tried to access invalid entity: <id>`).
4. Run in the console:
   ```
   entinfo 154872 160233 139981
   ```

The result looks like this:

```
REMOVED [21:14:03] ent=154872 netid=23800 type=VEHICLE model=-1216765807 pop=mission creator=3 (John) owner=3 (John) coords=215.3, -810.1, 30.7 heading=158.2
ent=139981 -> the server NEVER saw this entity (tracking for 12 min)
--- summary ---
1x  removed: VEHICLE / mission / model -1216765807
2x  never existed on the server (most likely a CLIENT handle sent to the server)
```

> 🕐 Only use ids from errors that appeared **after** the `ensure`. Entities removed before the resource started cannot be looked up.

## 📖 Reading the result

### ✅ `REMOVED`

It was a real entity and it was **deleted**.

```
REMOVED [21:14:03] ent=154872 netid=23800 type=VEHICLE model=-1216765807 pop=mission creator=3 (John) owner=3 (John) coords=215.3, -810.1, 30.7 heading=158.2
```

Some script stored that entity and kept using it after it was deleted. The `type`, `model`, `creator` and
`coords` tell you which system it belongs to — for example, a vehicle at the garage spawn point points to the
garage script.

**Fix:** check `DoesEntityExist(entity)` before using a stored entity, and clean up your references on `entityRemoved`.

### 🟡 `STILL EXISTS`

The entity is valid **right now**. The call probably happened during creation or migration. It is rare —
usually it means something used the entity too early, before it was ready on the server side.

### ❌ `the server NEVER saw this entity`

This is the most common case, and the most useful one.

```
ent=139981 -> the server NEVER saw this entity (tracking for 12 min)
```

A **client handle** (from `PlayerPedId()`, `GetVehiclePedIsIn()`, `GetClosestVehicle()`…) only means something
**on that player's game**. Some script is sending that number to the server through an event or callback, and
the server is calling natives on a number that means nothing there.

## 🛠️ Fixing "client handle sent to the server"

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

> 🧊 If the entity is not networked (created locally with `isNetwork = false`), the server can't see it at all.
> In that case, send the data you need (model, coords, heading) instead of the entity.

**Tips for finding the culprit:**

- Search your resources for `TriggerServerEvent`, callbacks, `lib.callback`, vRP tunnels, etc. whose arguments include `PlayerPedId()`, `GetVehiclePedIsIn`, `GetClosestVehicle`, `GetClosestObject` or similar variables.
- The pair of natives in the error tells you what the server does with the entity (see the hash table below). For example, *model + heading* usually means "save this vehicle/ped position".
- Use `entlast` to see what was being removed at the moment of the error.
- If the culprit is obfuscated or escrowed, stop candidate resources one at a time and watch whether the error stops.

## ⚙️ Configuration

### Convars (`server.cfg`, before the `ensure`)

| Convar | Default | Description |
|---|---|---|
| `entdebug_keep_minutes` | `30` | How long a removed entity stays in memory |
| `entdebug_track_created` | `true` | Also record entities on creation (needed for the *STILL EXISTS* result) |

```cfg
set entdebug_keep_minutes 60
set entdebug_track_created true
```

### Permissions (`config.lua`)

The server console can **always** run the commands. In game, access comes from `config.lua` or from an ACE:

| Option | Default | Description |
|---|---|---|
| `Config.perms` | `{ 'admin' }` | Permissions checked through framezero_bridge. Empty = only the ACEs apply |
| `Config.denied` | `"you don't have access to this."` | Message sent to a player without permission |

```lua
-- config.lua
Config.perms = { 'admin' }
```

Or, without touching the config:

```cfg
add_ace group.admin command.entinfo allow   # one command
add_ace group.admin command.entlast allow
add_ace group.admin command.entstats allow
add_ace group.admin command.entclear allow
add_ace group.admin entdebug.admin allow    # or all of them at once
```

### What "permission" means in each framework

The bridge translates `Config.perms` into whatever your framework understands:

| Framework | `Config.perms` accepts |
|---|---|
| **vRP · vRPex · Creative** | permission or group |
| **QBCore · Qbox** | job, gang, core permission or ACE |
| **ESX** | group (`admin`) or job |
| **Standalone** | ACE (`add_ace`) |

## 🧮 Native hash reference

The error prints the **hash** of the native, not its name. These are the most common server natives:

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

> 🔎 Did not find your hash? Your server build has all of them. Open `citizen/scripting/v8/natives_server.js` in your FXServer folder and search for the hash in lowercase (e.g. `0xdafcb3ec`).

## 🗂️ Structure

```
piercer_entdebug/
├── fxmanifest.lua   # resource manifest (depends on framezero_bridge)
├── config.lua       # ⭐ permissions and denied message
├── server.lua       # entity recording + entinfo/entlast/entstats/entclear commands
├── README.md        # this file (English)
├── README.pt-BR.md  # Portuguese version
└── LICENSE
```

### Flow

```
entityCreated ──▶ snapshot (type, model, netid, owner, coords, heading)
                     │
entityRemoved ──▶ snapshot + joins the entlast queue
                     │
             entinfo <ids> ──▶ removed[] · created[] · DoesEntityExist
                     │
                     ▼
   console (print) │ chat:addMessage │ framezero.Notify (no chat resource)
```

## ❓ Common problems

<details>
<summary><b>"a resource framezero_bridge não está iniciada"</b></summary>

The bridge must be running before entdebug. Check that:
- the folder is named exactly `framezero_bridge`;
- `ensure framezero_bridge` comes **before** `ensure piercer_entdebug` in `server.cfg`.

The manifest `dependency` already forces the order when both are in `server.cfg`, but both folders must exist in `resources/`.
</details>

<details>
<summary><b>I run the command and the answer is "you don't have access to this."</b></summary>

The player did not pass the permission check. Check:
- `Config.perms` in your `config.lua` (default `{ 'admin' }`);
- whether your framework really has that group/job/permission;
- or grant the ACE: `add_ace group.admin entdebug.admin allow`.

The server console never needs permission.
</details>

<details>
<summary><b>I run the command in game and nothing shows up</b></summary>

- Check F8 / the server console to make sure the resource started without errors.
- The output goes to the chat; if your server does **not** have the `chat` resource, it goes as a bridge notification — make sure your HUD/notify is working.
- Many ids at once produce many lines: start with `entinfo <one id>`.
</details>

<details>
<summary><b>`entinfo` says "the server NEVER saw this entity", but the entity existed</b></summary>

That is the expected result in two cases:
- a **client handle** sent to the server (the most common case — see the fix section above);
- the entity was created/removed **before** `ensure piercer_entdebug`. Tracking only starts when the resource starts.
</details>

<details>
<summary><b>The error keeps showing up. Now what?</b></summary>

entdebug does not block or change anything: it only helps you find the culprit.
1. Run `entinfo` with the ids from the new error.
2. Look at the pair of native hashes in the table: it tells you what the server tried to do.
3. Use `entlast 50` to see what was vanishing at the moment of the error.
4. If the suspect resource is obfuscated, stop them one at a time and watch whether the error stops.
</details>

<details>
<summary><b>Does it hurt performance? Can I leave it running forever?</b></summary>

Nothing noticeable: it stores a small table per entity and cleans up every minute. Still, it is a debugging
tool — start it, find the problem, then `stop piercer_entdebug`. In production, prefer a low
`entdebug_keep_minutes`.
</details>

<details>
<summary><b>Does it work with OneSync? What about local entities?</b></summary>

Yes, it requires OneSync like any server-side entity code. Entities created only on the client
(`isNetwork = false`) do not exist for the server — that is why they show up as `NEVER SAW`, and that is
exactly the most common case this tool detects.
</details>

<details>
<summary><b>Why doesn't the error show the resource name?</b></summary>

When the calling script handles the error (`pcall`, `try/catch`), only the `c-scripting-core` line is printed,
with no stack trace. That is exactly the case this tool was made for.
</details>

## 💬 Support & community

Found a bug, have an idea, or need help reading a result? Join the Discord:

<a href="https://discord.gg/jZ3vTmdjU7"><img src="https://img.shields.io/badge/Join%20the%20Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"></a>

Just ping **@piercer** there.

## 🤝 Contributing

Found a bug or have an idea? Contributions are welcome!
Open an *issue* or a *pull request* with a reproducible case (preferably with the error line and the
`entinfo` output).

If this resource helped you, leave a ⭐ on the repository — it helps other devs find the project.

## 📄 License

Distributed under the **MIT** license. Use, modify and redistribute freely, including on commercial servers.
Just keep the copyright notice. See [LICENSE](LICENSE).

<div align="center">

**[PIERCER13](https://github.com/PIERCER13)** · Discord **@piercer** · [discord.gg/jZ3vTmdjU7](https://discord.gg/jZ3vTmdjU7)

</div>
