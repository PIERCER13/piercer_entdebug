<div align="center">

# 🔍 piercer_entdebug

**Descubra o que está por trás dos erros `Tried to access invalid entity` no seu servidor FiveM.**

Um detetive de entidades que funciona em **qualquer framework**: ele registra tudo o que nasce e some no
servidor e, quando o erro aparece, te diz o que era cada ID — ou que o servidor **nunca conheceu** aquela
entidade. Sem adivinhar, sem procurar no escuro.

![FiveM](https://img.shields.io/badge/FiveM-resource-F40552?style=for-the-badge)
![Frameworks](https://img.shields.io/badge/ESX%20%C2%B7%20QBCore%20%C2%B7%20Qbox%20%C2%B7%20vRP%20%C2%B7%20standalone-2b2b2b?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-5.4-000080?style=for-the-badge&logo=lua&logoColor=white)
![License](https://img.shields.io/badge/licen%C3%A7a-MIT-22c55e?style=for-the-badge)
[![Discord](https://img.shields.io/badge/Discord-entrar-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/jZ3vTmdjU7)

🇺🇸 [Read in English](README.md)

</div>

---

## 🎯 Para que serve

Se o console do seu servidor tem linhas assim, você já conhece o problema:

```
[    c-scripting-core] script error in native 00000000dafcb3ec: Tried to access invalid entity: 132353
[    c-scripting-core] script error in native 00000000972cc383: Tried to access invalid entity: 132353
```

Algum script está chamando uma native numa entidade que **não existe mais** (ou que nunca existiu do lado do
servidor). O problema é que o log não diz **qual resource** fez isso, **o que era a entidade** nem **por quê**.
Com resources ofuscados ou com escrow fica pior: nem dá pra procurar o culpado no código.

O **piercer_entdebug** registra toda entidade que o servidor vê nascer e sumir. Quando o erro aparece, você
passa os IDs e ele responde na hora o que cada um era — ou que o servidor **nunca conheceu** aquele número.

| Situação | O que você vê |
|---|---|
| ❌ Sem o entdebug | `Tried to access invalid entity: 132353` … e mais nada |
| ✅ Com o entdebug | `REMOVED [21:14:03] ent=132353 netid=23800 type=VEHICLE model=-1216765807 …` |

> 💡 O ID do erro muda a cada entidade. Guarde **todos** os números das linhas de erro: rodando `entinfo` com vários IDs, o resultado vem agrupado no final.

## 🔧 Como funciona

1. **O servidor registra**: o `server.lua` escuta os eventos `entityCreated` e `entityRemoved` e guarda um retrato de cada entidade — tipo, modelo, network id, dono, criador, coordenadas, heading e population type.
2. **A memória se limpa sozinha**: a cada minuto ele apaga o que passou de `entdebug_keep_minutes` (padrão: 30). Entidades que continuam vivas também saem do registro quando deixam de existir.
3. **Você pergunta**: roda `entinfo <ids>` no console (ou no jogo, se tiver permissão) com os números do erro.
4. **Ele responde**: `REMOVED`, `STILL EXISTS` ou `the server NEVER saw this entity`, cada um com uma linha completa de detalhes e um resumo agrupado no final.
5. **A resposta chega no lugar certo**: no console vai pro log; no jogo vai pro chat (ou pra uma notificação da [framezero_bridge](https://github.com/PIERCER13/framezero_bridge), se o servidor não tiver o resource `chat`).

```
entityCreated ──▶ snapshot ──▶ created[]
entityRemoved ──▶ snapshot ──▶ removed[]
                                 │
                     entinfo <ids>
                                 │
                                 ▼
                 REMOVED · STILL EXISTS · NEVER SAW
```

> 🧩 Quem cuida de permissão e notificação é a **framezero_bridge** (ESX, QBCore, Qbox, vRP, vRPex, Creative ou standalone). O `piercer_entdebug` é só a parte de investigação.

## ✨ O que ele faz

- 🔎 **Responde o que era cada ID** do erro, com tipo, modelo, netid, criador, dono, coordenadas e heading.
- 🧠 **Diz quando o servidor nunca viu a entidade** — o caso mais comum, e o mais útil: handle de cliente enviado pro servidor.
- 🧩 **Multi-framework** via framezero_bridge, sem mudar uma linha de código.
- 🖥️ **Funciona no console e no jogo** (com permissão), com o mesmo resultado.
- 📋 **Resumo agrupado** no final do `entinfo`, pra ver de primeira quantos IDs caíram em cada caso.
- 💤 **Custo zero parado**: só reage a `entityCreated` / `entityRemoved`, nada de loop pesado.
- 🔒 **Somente leitura**: nunca altera, move nem deleta entidades.
- 🧹 **Memória controlada**: retenção configurável e limpeza automática.
- ⏱️ **`entlast`** mostra o que estava sumindo na hora exata do erro.
- 📦 **Zero configuração obrigatória**: baixou, deu `ensure`, já está funcionando.

## 📋 Requisitos

| Requisito | Observação |
|---|---|
| Servidor **FiveM** | Qualquer artifact recente |
| **OneSync** | Necessário, como em qualquer código de entidade no servidor |
| **[framezero_bridge](https://github.com/PIERCER13/framezero_bridge)** | Dependência obrigatória: cuida de permissão e notificação. O `dependency` do manifest garante que ela sobe primeiro |
| Resource **`chat`** | Opcional. Sem ele, as respostas no jogo usam a notificação da bridge |

## 🚀 Instalação

1. Instale a **framezero_bridge** em `resources/`. A pasta precisa se chamar exatamente `framezero_bridge`.
2. Baixe este repositório (**Code › Download ZIP**) ou clone:
   ```bash
   git clone https://github.com/PIERCER13/piercer_entdebug.git
   ```
3. Coloque a pasta `piercer_entdebug` em `resources/` do seu servidor.
4. Coloque no `server.cfg` na ordem **framework → bridge → entdebug**:
   ```cfg
   ensure vrp              # ou es_extended, qb-core, qbx_core... (pule se for standalone)
   ensure framezero_bridge
   ensure piercer_entdebug
   ```
5. Suba o servidor. Você deve ver:
   ```
   [piercer_entdebug] running (keep 30 min, track created: true). Use "entinfo <ids>" after the error shows up.
   ```

> ⚠️ É uma ferramenta de diagnóstico: dá pra iniciar só quando precisar (`ensure piercer_entdebug` no console), sem deixar no `server.cfg` para sempre.

## 🎬 Uso rápido

1. `ensure piercer_entdebug`
2. Espere o erro aparecer de novo.
3. Copie o **número do final** das linhas novas (o `<id>` em `Tried to access invalid entity: <id>`).
4. Rode no console:
   ```
   entinfo 154872 160233 139981
   ```

O resultado vem assim:

```
REMOVED [21:14:03] ent=154872 netid=23800 type=VEHICLE model=-1216765807 pop=mission creator=3 (John) owner=3 (John) coords=215.3, -810.1, 30.7 heading=158.2
ent=139981 -> the server NEVER saw this entity (tracking for 12 min)
--- summary ---
1x  removed: VEHICLE / mission / model -1216765807
2x  never existed on the server (most likely a CLIENT handle sent to the server)
```

> 🕐 Use apenas IDs de erros que apareceram **depois** do `ensure`. Entidades removidas antes do resource subir não podem ser consultadas.

## 📖 Como ler o resultado

### ✅ `REMOVED`

Era uma entidade real e ela foi **deletada**.

```
REMOVED [21:14:03] ent=154872 netid=23800 type=VEHICLE model=-1216765807 pop=mission creator=3 (John) owner=3 (John) coords=215.3, -810.1, 30.7 heading=158.2
```

Algum script guardou essa entidade e continuou usando depois que ela foi deletada. O `type`, o `model`, o
`creator` e as `coords` dizem a qual sistema ela pertence — por exemplo, um veículo no ponto de spawn da
garagem aponta para o script de garagem.

**Correção:** use `DoesEntityExist(entity)` antes de usar uma entidade guardada e limpe suas referências no `entityRemoved`.

### 🟡 `STILL EXISTS`

A entidade é válida **agora**. Provavelmente a chamada aconteceu durante a criação ou a migração. É raro —
geralmente significa que algo tentou usar a entidade cedo demais, antes de ela estar pronta do lado do servidor.

### ❌ `the server NEVER saw this entity`

É o caso mais comum e o mais útil.

```
ent=139981 -> the server NEVER saw this entity (tracking for 12 min)
```

Um **handle de cliente** (de `PlayerPedId()`, `GetVehiclePedIsIn()`, `GetClosestVehicle()`…) só tem sentido
**no jogo daquele jogador**. Algum script está mandando esse número pro servidor por evento ou callback, e o
servidor chama natives num número que, pra ele, não significa nada.

## 🛠️ Corrigindo "handle de cliente enviado ao servidor"

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

> 🧊 Se a entidade não é networked (criada só no cliente com `isNetwork = false`), o servidor não enxerga ela de
> jeito nenhum. Nesse caso mande os dados que precisa (modelo, coords, heading) em vez da entidade.

**Dicas pra achar o culpado:**

- Procure nos seus resources por `TriggerServerEvent`, callbacks, `lib.callback`, tunnels do vRP etc. que recebem `PlayerPedId()`, `GetVehiclePedIsIn`, `GetClosestVehicle`, `GetClosestObject` ou variáveis assim como argumento.
- O par de natives no erro diz o que o servidor faz com a entidade (veja a tabela de hashes abaixo). Por exemplo, *model + heading* geralmente é "salvar a posição deste veículo/ped".
- Use `entlast` pra ver o que estava sendo removido na hora do erro.
- Se o culpado for ofuscado ou escrow, pare os resources suspeitos um por vez e veja se o erro para.

## ⚙️ Configuração

### Convars (`server.cfg`, antes do `ensure`)

| Convar | Padrão | Descrição |
|---|---|---|
| `entdebug_keep_minutes` | `30` | Quanto tempo uma entidade removida fica na memória |
| `entdebug_track_created` | `true` | Registra também as entidades criadas (necessário para o resultado *STILL EXISTS*) |

```cfg
set entdebug_keep_minutes 60
set entdebug_track_created true
```

### Permissões (`config.lua`)

O console do servidor **sempre** pode. Dentro do jogo, o acesso vem do `config.lua` ou de uma ACE:

| Opção | Padrão | Descrição |
|---|---|---|
| `Config.perms` | `{ 'admin' }` | Permissões consultadas pela framezero_bridge. Vazio = só valem as ACEs |
| `Config.denied` | `"you don't have access to this."` | Mensagem enviada a quem não tem permissão |

```lua
-- config.lua
Config.perms = { 'admin' }
```

Ou, sem mexer no config:

```cfg
add_ace group.admin command.entinfo allow   # um comando
add_ace group.admin command.entlast allow
add_ace group.admin command.entstats allow
add_ace group.admin command.entclear allow
add_ace group.admin entdebug.admin allow    # ou todos de uma vez
```

### O que é "permissão" em cada framework

A bridge traduz `Config.perms` para o que o seu framework entende:

| Framework | `Config.perms` aceita |
|---|---|
| **vRP · vRPex · Creative** | permissão ou grupo |
| **QBCore · Qbox** | job, gang, permissão do core ou ACE |
| **ESX** | grupo (`admin`) ou job |
| **Standalone** | ACE (`add_ace`) |

## 🧮 Tabela de hashes de natives

O erro mostra o **hash** da native, não o nome. Estas são as natives de servidor mais comuns:

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

> 🔎 Não achou o hash? O build do seu servidor tem todas. Abra `citizen/scripting/v8/natives_server.js` na pasta do FXServer e procure o hash em minúsculas (ex.: `0xdafcb3ec`).

## 🗂️ Estrutura

```
piercer_entdebug/
├── fxmanifest.lua   # manifesto do resource (depende da framezero_bridge)
├── config.lua       # ⭐ permissões e mensagem de acesso negado
├── server.lua       # registro das entidades + comandos entinfo/entlast/entstats/entclear
├── README.md        # este arquivo (inglês)
├── README.pt-BR.md  # versão em português
└── LICENSE
```

### Fluxo

```
entityCreated ──▶ snapshot (tipo, modelo, netid, dono, coords, heading)
                     │
entityRemoved ──▶ snapshot + entra na fila do entlast
                     │
             entinfo <ids> ──▶ removed[] · created[] · DoesEntityExist
                     │
                     ▼
   console (print) │ chat:addMessage │ framezero.Notify (sem o resource chat)
```

## ❓ Problemas comuns

<details>
<summary><b>"a resource framezero_bridge não está iniciada"</b></summary>

A bridge precisa estar rodando antes do entdebug. Confira se:
- a pasta se chama exatamente `framezero_bridge`;
- `ensure framezero_bridge` vem **antes** de `ensure piercer_entdebug` no `server.cfg`.

O `dependency` do manifest já força a ordem quando as duas estão no `server.cfg`, mas as duas pastas precisam existir em `resources/`.
</details>

<details>
<summary><b>Rodo o comando e a resposta é "you don't have access to this."</b></summary>

O jogador não passou na checagem de permissão. Confira:
- `Config.perms` no seu `config.lua` (padrão `{ 'admin' }`);
- se o seu framework tem mesmo esse grupo/job/permissão;
- ou libere a ACE: `add_ace group.admin entdebug.admin allow`.

O console do servidor nunca precisa de permissão.
</details>

<details>
<summary><b>Rodo o comando no jogo e nada aparece</b></summary>

- Confira em F8 / console do servidor se o resource iniciou sem erro.
- O resultado vai pro chat; se o seu servidor **não** tem o resource `chat`, ele vai como notificação da bridge — verifique se o seu HUD/notify está funcionando.
- Muitos IDs de uma vez geram muitas linhas: comece com `entinfo <um id>`.
</details>

<details>
<summary><b>`entinfo` responde "the server NEVER saw this entity", mas a entidade existia</b></summary>

É o resultado esperado em dois casos:
- **handle de cliente** enviado ao servidor (o caso mais comum — veja a seção de correção acima);
- a entidade foi criada/removida **antes** do `ensure piercer_entdebug`. O rastreio só começa quando o resource sobe.
</details>

<details>
<summary><b>O erro continua aparecendo. E agora?</b></summary>

O entdebug não bloqueia nem altera nada: ele só te ajuda a achar o culpado.
1. Rode `entinfo` com os IDs do erro novo.
2. Veja o par de natives/hashes na tabela: ele diz o que o servidor tentou fazer.
3. Use `entlast 50` pra ver o que sumia na hora do erro.
4. Se o resource suspeito for ofuscado, pare um por vez e veja se o erro para.
</details>

<details>
<summary><b>Pesa no servidor? Posso deixar ligado pra sempre?</b></summary>

Nada perceptível: ele guarda uma tabela pequena por entidade e limpa a cada minuto. Mesmo assim, é uma
ferramenta de diagnóstico — ligue, ache o problema e dê `stop piercer_entdebug`. Em produção, prefira
`entdebug_keep_minutes` baixo.
</details>

<details>
<summary><b>Funciona com OneSync? E com entidades locais?</b></summary>

Sim, precisa de OneSync como qualquer código de entidade no servidor. Entidades criadas só no cliente
(`isNetwork = false`) não existem pro servidor — por isso elas caem no `NEVER SAW`, e é justamente o
caso mais comum que a ferramenta detecta.
</details>

<details>
<summary><b>Por que o erro não mostra o nome do resource?</b></summary>

Quando o script que chamou trata o erro (`pcall`, `try/catch`), só a linha do `c-scripting-core` é impressa,
sem stack trace. É exatamente pra esse caso que essa ferramenta existe.
</details>

## 💬 Suporte e comunidade

Dúvidas, sugestões ou precisa de ajuda pra ler um resultado? Entra no Discord:

<a href="https://discord.gg/jZ3vTmdjU7"><img src="https://img.shields.io/badge/Entrar%20no%20Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"></a>

Lá é só chamar o **@piercer**.

## 🤝 Contribuindo

Achou um bug ou tem uma ideia? Contribuições são bem-vindas!
Abra uma *issue* ou *pull request* com o caso reproduzível (de preferência com a linha de erro e o resultado
do `entinfo`).

Se esse resource te ajudou, deixa uma ⭐ no repositório, isso ajuda outros devs a encontrarem o projeto.

## 📄 Licença

Distribuído sob a licença **MIT**. Use, modifique e redistribua à vontade, inclusive em servidores comerciais.
Só mantenha o aviso de copyright. Veja [LICENSE](LICENSE).

<div align="center">

**[PIERCER13](https://github.com/PIERCER13)** · Discord **@piercer** · [discord.gg/jZ3vTmdjU7](https://discord.gg/jZ3vTmdjU7)

</div>
