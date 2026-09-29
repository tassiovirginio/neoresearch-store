--[[
  NeoResearch Plugin: Chat Interno & Assistente do Laboratório (Widget Flutuante)
  Target: chat_bot
  Tipo de Interface: floating (Gaveta / Janela Flutuante de Bate-Papo)

  Canal de comunicação interno em tempo real para os membros do laboratório
  com integração nativa a eventos do grupo e respostas a comandos acadêmicos (@bot).
--]]

plugin = {
    id = "internal_chat",
    name = "Chat Interno & Assistente",
    version = "1.0.0",
    author = "NeoResearch Oficial",
    description = "Bate-papo flutuante em tempo real entre os membros do laboratório com assistente acadêmico automatizado.",
    target = "chat_bot",
    default_enabled = true,
    ui = {
        type = "floating",
        widget_id = "floating-group-chat",
        title = "Chat do Laboratório",
        icon = "💬",
        badge = "Ao Vivo",
        tooltip = "Abrir Chat Interno do Laboratório",
        dock_position = "bottom-right",
        settings = {
            {
                key = "bot_name",
                label = "Nome do Assistente Virtual",
                type = "text",
                placeholder = "Ex: NeoBot, Sofia, Jarvis",
                default = "NeoBot",
                description = "Nome de exibição do assistente nas respostas automáticas."
            },
            {
                key = "auto_reply",
                label = "Ativar Respostas Automáticas",
                type = "checkbox",
                default = "true",
                description = "Responder automaticamente no chat quando alguém enviar comandos ou mencionar o assistente."
            }
        },
        guide = {
            title = "Como utilizar o Chat Interno",
            steps = {
                "Clique no botão flutuante 💬 no canto inferior direito da tela.",
                "Envie mensagens diretamente para outros pesquisadores do seu laboratório.",
                "Para interagir com o assistente virtual, use comandos como `/ajuda`, `/eventos`, `/membros`, `/projetos`, `/defesas` ou mencione `@bot`."
            },
            commands = {
                { cmd = "/ajuda", desc = "Exibe menu de comandos e ajuda do chat." },
                { cmd = "/eventos", desc = "Lista próximos prazos e eventos acadêmicos." },
                { cmd = "/membros", desc = "Exibe integrantes do laboratório." },
                { cmd = "/projetos", desc = "Lista projetos de pesquisa em andamento." },
                { cmd = "/publicacoes", desc = "Exibe as publicações mais recentes." },
                { cmd = "/defesas", desc = "Exibe as próximas defesas agendadas." },
                { cmd = "/status", desc = "Exibe status e dados do grupo." }
            }
        }
    }
}

local function format_help(group_name, bot_name)
    local name = bot_name or "NeoBot"
    return "🤖 *" .. name .. " — Assistente de Pesquisa*\n" ..
           "🏢 *Grupo:* " .. (group_name or "Laboratório") .. "\n\n" ..
           "Estes são os comandos disponíveis no chat:\n\n" ..
           "📅 `/eventos` — Prazos e congressos de interesse\n" ..
           "👥 `/membros` — Integrantes e pesquisadores da equipe\n" ..
           "🔬 `/projetos` — Linhas e projetos de pesquisa em andamento\n" ..
           "📚 `/publicacoes` — Últimos artigos científicos cadastrados\n" ..
           "🎓 `/defesas` — Próximas bancas e defesas agendadas\n" ..
           "⚡ `/status` — Informações do laboratório e integridade do chat\n\n" ..
           "_Dica: Você também pode conversar livremente com os colegas do laboratório neste canal!_"
end

local function format_events(group_name, events)
    if not events or #events == 0 then
        return "📅 *Eventos Acadêmicos (" .. (group_name or "Laboratório") .. ")*\n\n" ..
               "Nenhum evento acadêmico com prazos futuros cadastrado no momento."
    end

    local text = "📅 *Próximos Eventos & Prazos (" .. (group_name or "Laboratório") .. ")*\n\n"
    local count = 0
    for _, ev in ipairs(events) do
        count = count + 1
        if count > 5 then break end
        text = text .. "• *" .. (ev.name or "Evento") .. "* (" .. (ev.acronym or "") .. ") — Qualis: `" .. (ev.qualis or "S/Q") .. "`\n"
        if ev.occurrences and #ev.occurrences > 0 then
            for _, occ in ipairs(ev.occurrences) do
                if occ.tracks and #occ.tracks > 0 then
                    for _, tr in ipairs(occ.tracks) do
                        text = text .. "  └ ⏳ *" .. (tr.name or "Submissão") .. "*: `" .. (tr.deadline or "A definir") .. "`\n"
                    end
                end
            end
        end
        text = text .. "\n"
    end
    return text
end

local function format_members(group_name, members)
    if not members or #members == 0 then
        return "👥 *Membros do Laboratório (" .. (group_name or "") .. ")*\n\nNenhum membro registrado."
    end

    local text = "👥 *Membros do Laboratório (" .. (group_name or "") .. ")*\n\n"
    for _, m in ipairs(members) do
        local role = m.role or "Membro"
        local emoji = "👤"
        if role:lower():find("lider") or role:lower():find("líder") or role:lower():find("admin") then
            emoji = "👑"
        elseif role:lower():find("doutor") or role:lower():find("docente") or role:lower():find("professor") then
            emoji = "🎓"
        elseif role:lower():find("aluno") or role:lower():find("mestrand") or role:lower():find("bolsista") then
            emoji = "🎒"
        end
        text = text .. emoji .. " *" .. (m.name or "Pesquisador") .. "* — `" .. role .. "`\n"
    end
    return text
end

local function format_projects(group_name, projects)
    if not projects or #projects == 0 then
        return "🔬 *Projetos de Pesquisa (" .. (group_name or "") .. ")*\n\nNenhum projeto cadastrado."
    end

    local text = "🔬 *Projetos de Pesquisa em Andamento (" .. (group_name or "") .. ")*\n\n"
    for i, p in ipairs(projects) do
        if i > 6 then break end
        local status = p.status or "Ativo"
        local status_emoji = (status:lower() == "concluido" or status:lower() == "concluído") and "✅" or "⏳"
        text = text .. status_emoji .. " *" .. (p.title or "Sem título") .. "*\n"
        if p.description and p.description ~= "" then
            local desc = p.description:sub(1, 100)
            if #p.description > 100 then desc = desc .. "..." end
            text = text .. "  _" .. desc .. "_\n"
        end
        text = text .. "\n"
    end
    return text
end

local function format_defenses(group_name, defenses)
    if not defenses or #defenses == 0 then
        return "🎓 *Defesas & Bancas (" .. (group_name or "") .. ")*\n\nNenhuma defesa agendada no momento."
    end

    local text = "🎓 *Próximas Defesas Agendadas (" .. (group_name or "") .. ")*\n\n"
    for i, d in ipairs(defenses) do
        if i > 5 then break end
        text = text .. "• *" .. (d.defense_type or "Defesa") .. "* (" .. (d.degree_level or "") .. ")\n" ..
               "  👤 *Estudante:* " .. (d.student or "Discente") .. "\n" ..
               "  📅 *Data:* " .. (d.date or "") .. " às " .. (d.time or "") .. "\n" ..
               "  📖 *Título:* _" .. (d.title or "Sem título") .. "_\n\n"
    end
    return text
end

local function format_publications(group_name, publications)
    if not publications or #publications == 0 then
        return "📚 *Publicações Recentes (" .. (group_name or "") .. ")*\n\nNenhuma publicação registrada."
    end

    local text = "📚 *Últimas Publicações do Laboratório (" .. (group_name or "") .. ")*\n\n"
    for i, pub in ipairs(publications) do
        if i > 5 then break end
        text = text .. "• *" .. (pub.title or "Artigo") .. "* (" .. tostring(pub.year or "") .. ")\n" ..
               "  🏛️ _" .. (pub.venue or "Veículo não especificado") .. "_\n" ..
               "  ✍️ " .. (pub.authors or "") .. "\n\n"
    end
    return text
end

--[[
  Processamento de mensagens enviadas no chat interno.
  Responde a comandos (/ajuda, /eventos, etc.) e menções (@bot).
  Mensagens normais entre colegas retornam nil (não disparam resposta do bot).
--]]
function on_message(msg)
    if not msg or not msg.text then
        return nil
    end

    local raw = msg.text:match("^%s*(.-)%s*$")
    if raw == "" then
        return nil
    end

    local config = msg.config or {}
    local bot_name = config.bot_name or "NeoBot"
    local auto_reply = config.auto_reply
    if auto_reply == "false" or auto_reply == false then
        return nil
    end

    local lower = raw:lower()
    local words = {}
    for w in lower:gmatch("%S+") do
        table.insert(words, w)
    end

    local first = words[1] or ""
    local cmd = ""
    local is_explicit_command = false

    -- Inicia com / (ex: /ajuda, /eventos, /membros)
    if first:sub(1, 1) == "/" then
        is_explicit_command = true
        cmd = first:sub(2)
        if cmd:find("@") then
            cmd = cmd:match("([^@]+)") or ""
        end
    -- Inicia com menção @ (ex: @bot, @neobot, !bot)
    elseif first:sub(1, 1) == "@" or first:sub(1, 1) == "!" then
        local tag = first:sub(2)
        if tag == "bot" or tag == "neobot" or tag == "assistente" or tag:lower() == bot_name:lower() then
            is_explicit_command = true
            if #words >= 2 then
                cmd = words[2]
                if cmd:sub(1, 1) == "/" then
                    cmd = cmd:sub(2)
                end
            else
                cmd = "ajuda"
            end
        end
    end

    if not is_explicit_command then
        -- Mensagem de conversa normal entre pesquisadores: não responder
        return nil
    end

    if cmd == "start" or cmd == "ajuda" or cmd == "help" then
        return format_help(msg.group_name, bot_name)
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
        return "🤖 *Status do Chat do Laboratório*\n\n" ..
               "🏢 *Grupo:* " .. (msg.group_name or "") .. "\n" ..
               "🤖 *Assistente Virtual:* " .. bot_name .. "\n" ..
               "🟢 *Conexão:* Ao Vivo (SSE Integrado)\n" ..
               "⚡ *Versão do Plugin:* v1.0.0\n\n" ..
               "_O chat interno está operacional e pronto para colaboração em tempo real!_"
    elseif cmd == "teste" or cmd == "test" then
        return "🧪 *Teste de Conexão Bem-Sucedido!*\n\nO chat interno e o assistente *" .. bot_name .. "* estão operacionais e conectados ao grupo.\n\nEnvie `/ajuda` para ver os comandos disponíveis."
    end

    return "❓ Comando `/" .. cmd .. "` não reconhecido.\nEnvie `/ajuda` para ver a lista de comandos disponíveis."
end
