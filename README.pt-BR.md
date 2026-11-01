# piercer_entdebug

> Descubra o que está por trás dos erros `Tried to access invalid entity` no seu servidor FiveM.

🇺🇸 [Read in English](README.md) · 💬 [Discord FrameZero](https://discord.gg/jZ3vTmdjU7)

```
[    c-scripting-core] script error in native 00000000dafcb3ec: Tried to access invalid entity: 132353
[    c-scripting-core] script error in native 00000000972cc383: Tried to access invalid entity: 132353
```

Se o seu console está assim, você sabe que *algum* script está chamando uma native numa entidade que não existe. Só que o log não diz **qual resource**, **qual entidade** nem **por quê**. Com resources ofuscados ou com escrow fica pior: nem dá pra procurar o culpado no código.

O **piercer_entdebug** registra toda entidade que o servidor vê nascer e sumir. Quando o erro aparece, você passa os IDs e ele diz o que cada entidade era, ou que o servidor **nunca conheceu** aquela entidade.

- Roda em qualquer framework através da **framezero_bridge** (vRP, vRPex, ESX, QBCore, Qbox, Creative ou standalone) — dependência obrigatória.
- Só server-side. Só responde a quem roda um comando.
- Sem custo parado: só reage a `entityCreated` / `entityRemoved`.
- Somente leitura. Nunca altera nem deleta entidades.

---

## Instalação

1. Baixe ou clone **os dois** repositórios na pasta `resources`:
   ```
   resources/framezero_bridge
   resources/piercer_entdebug
   ```
   A `framezero_bridge` é obrigatória: cuida da permissão (grupo/job/ACE do framework) e da notificação no jogo. O FiveM inicia ela antes por causa do `dependency` no manifest. Baixe ela no [Discord da FrameZero](https://discord.gg/jZ3vTmdjU7).
2. Inicie pelo console do servidor (não precisa colocar no `server.cfg`, é uma ferramenta de diagnóstico):
   ```
   refresh
   ensure piercer_entdebug
   ```
3. Deve aparecer:
   ```
   [piercer_entdebug] running (keep 30 min, track created: true). Use "entinfo <ids>" after the error shows up.
   ```

> Inicie **antes** do erro acontecer. Entidades removidas antes do resource subir não podem ser consultadas.

---

## Comandos

| Comando | O que faz |
|---|---|
| `entinfo <id> [id ...]` | Mostra o que cada entidade era, com um resumo agrupado no final. Use os números do final das linhas de erro. |
| `entlast [n]` | Lista as últimas `n` entidades removidas (padrão `20`). Útil pra ver o que estava sumindo na hora do erro. |
| `entstats` | Há quanto tempo está registrando e quantas entidades estão na memória. |
| `entclear` | Apaga tudo que foi registrado e zera o contador de tempo. |

Todos funcionam no **console do servidor** (Live Console do txAdmin ou a janela do FXServer). Para usar dentro do jogo, libere o jogador pelo framework (via `framezero_bridge`) ou por ACE:

```lua
-- config.lua
Config.perms = { 'admin' }  -- grupo do ESX / job, gang ou permission do QBCore-Qbox / grupo do vRP / ACE no standalone
```

```cfg
-- ou então, sem mexer no config:
add_ace group.admin command.entinfo allow   # um comando
add_ace group.admin command.entlast allow
add_ace group.admin entdebug.admin allow    # ou todos de uma vez
```

No jogo, a resposta aparece no chat (ou numa notificação, quando o servidor não tem o resource `chat`).

---

## Configuração

Convars opcionais. Coloque no `server.cfg` **antes** do `ensure piercer_entdebug`:

| Convar | Padrão | O que faz |
|---|---|---|
| `entdebug_keep_minutes` | `30` | Quanto tempo uma entidade removida fica na memória. |
| `entdebug_track_created` | `true` | Registra também as entidades criadas (necessário para o resultado *STILL EXISTS*). |

```cfg
set entdebug_keep_minutes 60
set entdebug_track_created true
```

### Permissões

Quem pode rodar os comandos dentro do jogo fica no `config.lua` (o console do servidor sempre pode):

| Config | Padrão | O que faz |
|---|---|---|
| `Config.perms` | `{ 'admin' }` | Permissões consultadas pela `framezero_bridge`. Vazio = só valem as ACEs. |
| `Config.denied` | `you don't have access to this.` | Mensagem enviada a quem não tem permissão. |

---

## Como usar

1. `ensure piercer_entdebug`
2. Espere o erro aparecer de novo.
3. Copie o **número do final** das linhas de erro novas (o `<id>` em `Tried to access invalid entity: <id>`).
4. Rode:
   ```
   entinfo 154872 160233 139981
   ```

> Use os números reais, e não `<id>`. E use só IDs de erros que apareceram **depois** do `ensure`.

### Como ler o resultado

**`REMOVED`**: era uma entidade real e foi deletada.

```
REMOVED [21:14:03] ent=154872 netid=23800 type=VEHICLE model=-1216765807 pop=mission creator=3 (John) owner=3 (John) coords=215.3, -810.1, 30.7 heading=158.2
```

Algum script guardou essa entidade e continuou usando depois que ela foi deletada. O `type`, o `model`, o `creator` e as `coords` dizem a qual sistema ela pertence. Por exemplo, um veículo no ponto de spawn da garagem aponta para o script de garagem. **Correção:** use `DoesEntityExist(entity)` antes de usar uma entidade guardada e limpe suas referências no `entityRemoved`.

**`STILL EXISTS`**: a entidade é válida agora. Provavelmente a chamada aconteceu durante a criação ou a migração. É raro.

**`the server NEVER saw this entity`**: é o caso mais comum, e o mais útil.

```
ent=139981 -> the server NEVER saw this entity (tracking for 12 min)
--- summary ---
3x  never existed on the server (most likely a CLIENT handle sent to the server)
```

O handle de uma entidade no **cliente** (de `PlayerPedId()`, `GetVehiclePedIsIn()`, `GetClosestVehicle()`…) só tem sentido **no jogo daquele jogador**. Algum script está mandando esse número pro servidor por evento ou callback, e o servidor chama natives num número que pra ele não significa nada.

---

## Corrigindo "handle de cliente enviado ao servidor"

Procure código do cliente que manda a entidade crua num evento:

```lua
-- ❌ client: manda o handle local
local veh = GetVehiclePedIsIn(PlayerPedId(), false)
TriggerServerEvent('meuscript:salvarVeiculo', veh)

-- ❌ server: usa como se fosse uma entidade do servidor
RegisterNetEvent('meuscript:salvarVeiculo', function(veh)
    local model = GetEntityModel(veh)      -- Tried to access invalid entity
    local heading = GetEntityHeading(veh)  -- Tried to access invalid entity
end)
```

Mande o **network id** e converta no servidor:

```lua
-- ✅ client
local veh = GetVehiclePedIsIn(PlayerPedId(), false)
TriggerServerEvent('meuscript:salvarVeiculo', NetworkGetNetworkIdFromEntity(veh)) -- ou VehToNet(veh)

-- ✅ server
RegisterNetEvent('meuscript:salvarVeiculo', function(netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    local model = GetEntityModel(veh)
    local heading = GetEntityHeading(veh)
end)
```

> Se a entidade não é networked (criada só no cliente com `isNetwork = false`), o servidor não enxerga ela de jeito nenhum. Nesse caso mande os dados que precisa (modelo, coords, heading) em vez da entidade.

**Dicas pra achar o culpado:**
- Procure nos seus resources por `TriggerServerEvent`, callbacks, `lib.callback`, tunnels do vRP etc. que recebem `PlayerPedId()`, `GetVehiclePedIsIn`, `GetClosestVehicle`, `GetClosestObject` ou variáveis assim como argumento.
- O par de natives no erro diz o que o servidor faz com a entidade (veja a tabela abaixo). Por exemplo, *model + heading* geralmente é "salvar a posição deste veículo/ped".
- Se o culpado for ofuscado ou escrow, pare os resources suspeitos um por vez e veja se o erro para.

---

## Tabela de hashes de natives

O erro mostra o **hash** da native, não o nome. Estas são natives de servidor comuns:

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

Não está na lista? O build do seu servidor tem todas. Abra `citizen/scripting/v8/natives_server.js` na pasta do FXServer e procure o hash em minúsculas (ex: `0xdafcb3ec`).

---

## Perguntas frequentes

**Pesa no servidor?**
Nada perceptível. Guarda uma tabela pequena por entidade e limpa a cada minuto. As removidas expiram depois de `entdebug_keep_minutes`.

**Deixo ligado pra sempre?**
É uma ferramenta de diagnóstico. Liga, acha o problema e depois `stop piercer_entdebug`.

**Por que o erro não mostra o nome do resource?**
Quando o script que chamou trata o erro (`pcall`, `try/catch`), só a linha do `c-scripting-core` é impressa, sem stack trace. É exatamente pra esse caso que essa ferramenta existe.

**Funciona com OneSync?**
Sim. Ela precisa do OneSync, como qualquer código de entidade no servidor.

---

## Suporte e comunidade

Achou um bug, tem uma ideia ou precisa de ajuda pra entender o resultado?

- 💬 **Discord FrameZero:** [discord.gg/jZ3vTmdjU7](https://discord.gg/jZ3vTmdjU7)
- 👤 **Autor:** `@piercer` no Discord

Pull requests são bem-vindos.

---

## Licença

[MIT](LICENSE) © PIERCER / FrameZero. Use, modifique e compartilhe à vontade. Uma ⭐ no repositório ajuda muito.
