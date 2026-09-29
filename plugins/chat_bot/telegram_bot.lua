--[[
  NeoResearch Plugin: Telegram Bot Notifier & Assistente
  Target: chat_bot
  Integração oficial com a API de Bots do Telegram (https://core.telegram.org/bots/api).
  Permite envio de alertas automáticos e atendimento a comandos acadêmicos.
]]

plugin = {
    id = "telegram_bot",
    name = "Telegram Bot Notifier & Assistente",
    version = "1.0.0",
    author = "NeoResearch Oficial",
    description = "Integração oficial com Telegram Bot API para envio de alertas, notificações de prazos e respostas a comandos de pesquisa.",
    target = "chat_bot",
    default_enabled = false,
    ui = {
        type = "tab",
        tab_id = "telegram",
        title = "Telegram Bot",
        icon = "✈️",
        badge = "Telegram",
        tooltip = "Configurar bot de Telegram para notificações e comandos do laboratório",
        settings = {
            {
                key = "bot_token",
                label = "Bot Token (@BotFather)",
                type = "password",
                placeholder = "Ex: 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11",
                description = "Token HTTP API gerado pelo @BotFather ao criar o bot no Telegram."
            },
            {
                key = "chat_id",
                label = "Chat ID do Grupo / Canal",
                type = "text",
                placeholder = "Ex: -1001234567890 ou @meucanal",
                description = "ID do grupo ou canal no Telegram onde o bot enviará mensagens e notificações."
            }
        },
        guide = {
            title = "Como configurar e utilizar o Telegram Bot",
            steps = {
                "Abra o aplicativo Telegram e inicie uma conversa com o **@BotFather**.",
                "Envie o comando `/newbot` e siga as instruções para definir o nome e o username do seu bot.",
                "Copie o **Token HTTP API** exibido pelo BotFather e cole no campo de configuração acima.",
                "Adicione o bot recém-criado como administrador no grupo de pesquisa ou canal desejado.",
                "Para descobrir o Chat ID do grupo, envie qualquer mensagem nele e acesse `@userinfobot` ou `@RawDataBot`.",
                "Cole o **Chat ID** acima, clique em **Salvar Configurações** e em seguida envie uma mensagem de teste."
            },
            commands = {
                { cmd = "/ajuda", desc = "Exibe menu de ajuda e comandos do bot." },
                { cmd = "/eventos", desc = "Lista próximos eventos acadêmicos e prazos de submissão." },
                { cmd = "/membros", desc = "Exibe pesquisadores e estudantes do grupo." },
                { cmd = "/projetos", desc = "Lista projetos de pesquisa em andamento." },
                { cmd = "/publicacoes", desc = "Exibe as publicações mais recentes do laboratório." },
                { cmd = "/defesas", desc = "Exibe as próximas defesas agendadas." },
                { cmd = "/status", desc = "Verifica integridade e dados do grupo." }
            }
        }
    }
}

--[[
  Envia uma mensagem via Telegram Bot API usando o cliente HTTP seguro injetado pelo NeoResearch.
]]
local function send_telegram_message(bot_token, chat_id, text, parse_mode)
    if not bot_token or bot_token == "" or not chat_id or chat_id == "" then
        log.warn("Telegram Bot: 'bot_token' ou 'chat_id' não configurados.")
        return false, "Configurações incompletas"
    end

    local url = "https://api.telegram.org/bot" .. bot_token .. "/sendMessage"
    local payload = json.encode({
        chat_id = chat_id,
        text = text,
        parse_mode = parse_mode or "Markdown"
    })

    local res = http.post(url, {
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = payload,
        timeout_secs = 10
    })

    if res.ok then
        log.info("Telegram: Mensagem enviada com sucesso para " .. chat_id)
        return true, res.body
    else
        log.error("Telegram: Falha ao enviar mensagem (status " .. res.status .. "): " .. (res.body or res.error or ""))
        return false, res.error or res.body
    end
end

local function format_help(group_name)
    return "🤖 *NeoResearch Telegram Bot*\n" ..
           "🏢 *Grupo:* " .. (group_name or "Grupo de Pesquisa") .. "\n\n" ..
           "Estes são os comandos disponíveis:\n\n" ..
           "📅 `/eventos` — Conferências de interesse e datas de submissão\n" ..
           "👥 `/membros` — Integrantes e pesquisadores do laboratório\n" ..
           "📁 `/projetos` — Projetos de pesquisa em andamento\n" ..
           "🎓 `/defesas` — Próximas bancas de mestrado/doutorado e TCC\n" ..
           "📄 `/publicacoes` — Produção científica recente\n" ..
           "ℹ️ `/status` — Informações sobre a conexão do bot\n" ..
           "🔔 `/teste` — Envia um disparo de teste ao chat configurado\n\n" ..
           "_Dica: Você também pode usar @bot <comando> ou !bot <comando>._"
end

local function format_events(group_name, events)
    if not events or #events == 0 then
        return "📅 *Eventos de Interesse — " .. (group_name or "") .. "*\n\n" ..
               "Nenhum evento cadastrado no momento no painel do NeoResearch."
    end

    local out = "📅 *Eventos & Conferências — " .. (group_name or "") .. "*\n\n"
    local count = math.min(#events, 6)
    for i = 1, count do
        local ev = events[i]
        local qualis = (ev.qualis and ev.qualis ~= "") and (" [Qualis: " .. ev.qualis .. "]") or ""
        out = out .. i .. ". *" .. (ev.name or "") .. "* (" .. (ev.acronym or "") .. ")" .. qualis .. "\n"

        if ev.occurrences and #ev.occurrences > 0 then
            for _, occ in ipairs(ev.occurrences) do
                local date = (occ.date and occ.date ~= "") and ("🗓️ " .. occ.date) or "🗓️ A definir"
                out = out .. "   • Edição " .. (occ.edition or "") .. ": " .. (occ.city or "") .. " (" .. date .. ")\n"
                if occ.tracks and #occ.tracks > 0 then
                    for _, tr in ipairs(occ.tracks) do
                        out = out .. "     ⏰ Trilha _" .. (tr.name or "") .. "_: Prazo *" .. (tr.deadline or "") .. "*\n"
                    end
                end
            end
        end
        out = out .. "\n"
    end
    return out
end

local function format_members(group_name, members)
    if not members or #members == 0 then
        return "👥 *Integrantes — " .. (group_name or "") .. "*\n\nNenhum integrante cadastrado."
    end

    local out = "👥 *Equipe de Pesquisa — " .. (group_name or "") .. "*\n\n"
    for _, m in ipairs(members) do
        local role = (m.role or ""):lower()
        local icon = "🎓"
        if role == "leader" or role == "admin" then icon = "👑"
        elseif role == "researcher" then icon = "🔬" end

        out = out .. icon .. " *" .. (m.name or "Sem nome") .. "* (" .. (m.email or "") .. ")\n"
    end
    out = out .. "\n_Total de membros: " .. #members .. "_"
    return out
end

local function format_projects(group_name, projects)
    if not projects or #projects == 0 then
        return "📁 *Projetos — " .. (group_name or "") .. "*\n\nNenhum projeto registrado."
    end

    local out = "📁 *Projetos Ativos — " .. (group_name or "") .. "*\n\n"
    for i, p in ipairs(projects) do
        local st = (p.status == "active") and "🟢 Ativo" or "📝 " .. (p.status or "Planejado")
        out = out .. i .. ". *" .. (p.title or "") .. "* (" .. st .. ")\n"
        if p.description and p.description ~= "" then
            out = out .. "   _" .. p.description:sub(1, 90) .. "_\n"
        end
    end
    return out
end

local function format_defenses(group_name, defenses)
    if not defenses or #defenses == 0 then
        return "🎓 *Qualificações e Defesas — " .. (group_name or "") .. "*\n\nNenhuma defesa agendada."
    end

    local out = "🎓 *Bancas & Defesas Agendadas — " .. (group_name or "") .. "*\n\n"
    for i, d in ipairs(defenses) do
        local tipo = (d.defense_type == "qualification") and "Qualificação" or "Defesa"
        out = out .. i .. ". *" .. tipo .. "*: " .. (d.student or "") .. "\n"
        out = out .. "   🗓️ " .. (d.date or "") .. " às " .. (d.time or "") .. "\n"
        out = out .. "   📝 _\"" .. (d.title or "") .. "\"_\n\n"
    end
    return out
end

local function format_publications(group_name, publications)
    if not publications or #publications == 0 then
        return "📄 *Publicações — " .. (group_name or "") .. "*\n\nNenhuma publicação encontrada."
    end

    local out = "📄 *Últimas Produções Científicas — " .. (group_name or "") .. "*\n\n"
    local count = math.min(#publications, 5)
    for i = 1, count do
        local p = publications[i]
        out = out .. i .. ". *" .. (p.title or "") .. "* (" .. (p.year or "") .. ")\n"
        if p.venue and p.venue ~= "" then
            out = out .. "   🏛️ " .. p.venue .. "\n"
        end
        if p.authors and p.authors ~= "" then
            out = out .. "   👥 _" .. p.authors .. "_\n"
        end
        out = out .. "\n"
    end
    return out
end

--[[
  Função para emissão de notificações proativas do sistema para o chat do Telegram.
]]
function notify(event_type, payload, config)
    config = config or {}
    local token = config.bot_token
    local chat_id = config.chat_id

    if not token or not chat_id then
        return false, "bot_token ou chat_id ausentes na configuração do plugin."
    end

    local text = ""
    if event_type == "new_publication" then
        text = "📢 *Nova Publicação Registrada!*\n\n" ..
               "📝 *" .. (payload.title or "Sem título") .. "*\n" ..
               "👥 Autores: _" .. (payload.authors or "Equipe") .. "_\n" ..
               "🏛️ Veículo: " .. (payload.venue or "Periódico/Conferência") .. " (" .. (payload.year or "") .. ")\n"
    elseif event_type == "event_deadline" then
        text = "⏰ *Lembrete de Prazo de Submissão!*\n\n" ..
               "🎯 Evento: *" .. (payload.event_name or "") .. "* (" .. (payload.acronym or "") .. ")\n" ..
               "🏷️ Trilha: _" .. (payload.track_name or "") .. "_\n" ..
               "🗓️ Data Limite: *" .. (payload.deadline or "") .. "*\n"
    elseif event_type == "defense_scheduled" then
        text = "🎓 *Nova Defesa/Qualificação Agendada!*\n\n" ..
               "👤 Discente: *" .. (payload.student or "") .. "*\n" ..
               "📝 Título: _\"" .. (payload.title or "") .. "\"_\n" ..
               "🗓️ Data: *" .. (payload.date or "") .. " às " .. (payload.time or "") .. "*\n"
    else
        text = "🔔 *Notificação NeoResearch*: " .. (payload.message or "Novo evento no laboratório.")
    end

    return send_telegram_message(token, chat_id, text, "Markdown")
end

--[[
  Processamento de mensagens/comandos recebidos.
]]
function on_message(msg)
    if not msg or not msg.text then
        return nil
    end

    local raw = msg.text:match("^%s*(.-)%s*$")
    if raw == "" then
        return nil
    end

    local config = msg.config or {}
    local bot_token = config.bot_token or ""
    local chat_id = config.chat_id or ""

    local lower = raw:lower()
    local words = {}
    for w in lower:gmatch("%S+") do
        table.insert(words, w)
    end

    local first = words[1] or ""
    local cmd = ""
    local is_explicit_command = false

    if first:sub(1, 1) == "/" then
        is_explicit_command = true
        cmd = first:sub(2)
        if cmd:find("@") then
            cmd = cmd:match("([^@]+)") or ""
        end
    elseif first:sub(1, 1) == "@" or first:sub(1, 1) == "!" then
        is_explicit_command = true
        if #words >= 2 then
            cmd = words[2]
            if cmd:sub(1, 1) == "/" then
                cmd = cmd:sub(2)
            end
            if cmd:find("@") then
                cmd = cmd:match("([^@]+)") or ""
            end
        else
            cmd = "ajuda"
        end
    else
        cmd = first
    end

    if cmd == "start" or cmd == "ajuda" or cmd == "help" then
        return format_help(msg.group_name)
    elseif cmd == "eventos" or cmd == "events" then
        return format_events(msg.group_name, msg.events)
    elseif cmd == "membros" or cmd == "equipe" then
        return format_members(msg.group_name, msg.members)
    elseif cmd == "projetos" or cmd == "projects" then
        return format_projects(msg.group_name, msg.projects)
    elseif cmd == "defesas" or cmd == "bancas" then
        return format_defenses(msg.group_name, msg.defenses)
    elseif cmd == "publicacoes" or cmd == "artigos" then
        return format_publications(msg.group_name, msg.publications)
    elseif cmd == "status" or cmd == "info" then
        local token_info = (bot_token ~= "") and "🟢 Configurado (" .. bot_token:sub(1, 6) .. "...)" or "🔴 Não configurado"
        local chat_info = (chat_id ~= "") and "🟢 " .. chat_id or "🔴 Não configurado"
        return "🤖 *Status do Plugin Telegram Bot*\n\n" ..
               "🏢 *Grupo:* " .. (msg.group_name or "") .. "\n" ..
               "🔑 *Bot Token:* " .. token_info .. "\n" ..
               "💬 *Chat ID / Canal:* " .. chat_info .. "\n" ..
               "⚡ *Versão:* v1.0.0\n\n" ..
               "_Para configurar o token e chat_id, edite a configuração deste plugin no NeoResearch._"
    elseif cmd == "teste" or cmd == "test" then
        if bot_token == "" or chat_id == "" then
            return "⚠️ *Telegram Bot*: O 'bot_token' e 'chat_id' precisam estar configurados nas opções do plugin para enviar disparos ao Telegram."
        end
        return "🧪 *Conexão Ativa*: O bot NeoResearch está operacional e conectado com sucesso a este grupo!\n\nEnvie `/ajuda` para ver os comandos disponíveis."
    end

    -- Se começou expressamente com comando de bot mas não foi reconhecido
    if is_explicit_command then
        return "❓ Comando `/" .. cmd .. "` não reconhecido.\nEnvie `/ajuda` para ver os comandos."
    end

    return nil
end
