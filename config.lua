Config = {}


-- Quem pode usar os comandos dentro do jogo. O console do servidor sempre pode.
-- Aceita o que o seu framework entende por permissão (via framezero_bridge):
-- vRP: permissão/grupo · QBCore/Qbox: job, gang, grupo ou ACE · ESX: grupo ou job · standalone: ACE
Config.perms = { 'admin' }

-- As ACEs abaixo continuam valendo, mesmo com Config.perms vazio:
--   add_ace group.admin command.entinfo allow
--   add_ace group.admin entdebug.admin allow

Config.denied = "you don't have access to this."
