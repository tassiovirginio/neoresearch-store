--[[
  NeoResearch Plugin: WhatsApp Bot & Assistente
  Target: whatsapp_bot
  Módulo de processamento inteligente de mensagens recebidas via WhatsApp.
  Permite que cada grupo de pesquisa personalize comandos, respostas e fluxos.
]]

plugin = {
    id = "whatsapp_bot",
    name = "WhatsApp Bot & Assistente",
    version = "1.0.0",
    author = "NeoResearch Oficial",
    description = "Processamento modular de mensagens e comandos (@bot) para grupos e chats de WhatsApp com respostas customizáveis.",
    target = "whatsapp_bot",
    default_enabled = true,
    ui = {
        type = "tab",
        tab_id = "whatsapp",
        title = "WhatsApp Bot",
        icon = "💬",
        badge = "WhatsApp",
        tooltip = "Configurar assistente virtual e bot do WhatsApp",
        custom_component = "whatsapp_native",
        guide = {
            title = "Como utilizar o Bot no WhatsApp",
            commands = {
                { cmd = "!ajuda", desc = "Exibe menu de ajuda e comandos do bot." },
                { cmd = "!eventos", desc = "Lista próximos eventos acadêmicos e prazos de submissão." },
                { cmd = "!membros", desc = "Exibe pesquisadores e estudantes do grupo." },
                { cmd = "!projetos", desc = "Lista projetos de pesquisa em andamento." },
                { cmd = "!publicacoes", desc = "Exibe as publicações mais recentes do laboratório." },
                { cmd = "!defesas", desc = "Exibe as próximas defesas agendadas." },
                { cmd = "!status", desc = "Verifica integridade e dados do grupo." }
            }
        }
    }
}

local function format_help(group_name)
    return "🤖 *Assistente Virtual NeoResearch*\n" ..
           "🏢 *Grupo:* " .. (group_name or "Grupo de Pesquisa") .. "\n\n" ..
           "Estes são os comandos que posso atender:\n\n" ..
           "📅 *@bot eventos* — Lista os eventos e prazos de submissão\n" ..
           "👥 *@bot membros* — Integrantes da equipe e contatos\n" ..
           "📁 *@bot projetos* — Projetos de pesquisa em andamento\n" ..
           "🎓 *@bot defesas* — Próximas qualificações e defesas\n" ..
           "📄 *@bot publicações* — Artigos e produções recentes\n" ..
           "ℹ️ *@bot status* — Informações de integração do bot\n\n" ..
           "_Dica: Você também pode usar !bot ou /bot._"
end

local function format_events(group_name, events)
    if not events or #events == 0 then
        return "📅 *Eventos de Interesse — " .. (group_name or "") .. "*\n\n" ..
               "Nenhum evento cadastrado no momento.\n" ..
               "Acesse o painel do NeoResearch para adicionar novos eventos."
    end

    local out = "📅 *Eventos de Interesse — " .. (group_name or "") .. "*\n\n"
    local count = math.min(#events, 6)
    for i = 1, count do
        local ev = events[i]
        local qualis_badge = ""
        if ev.qualis and ev.qualis ~= "" then
            qualis_badge = " [Qualis: " .. ev.qualis .. "]"
        end
        out = out .. i .. ". *" .. (ev.name or "") .. "* (" .. (ev.acronym or "") .. ")" .. qualis_badge .. "\n"

        if ev.occurrences and #ev.occurrences > 0 then
            local occ_count = math.min(#ev.occurrences, 2)
            for j = 1, occ_count do
                local occ = ev.occurrences[j]
                local date = (occ.date and occ.date ~= "") and ("🗓️ " .. occ.date) or "🗓️ A definir"
                out = out .. "   • Edição " .. (occ.edition or "") .. ": " .. (occ.city or "") .. " - " .. date .. "\n"

                if occ.tracks and #occ.tracks > 0 then
                    local track_count = math.min(#occ.tracks, 2)
                    for k = 1, track_count do
                        local tr = occ.tracks[k]
                        out = out .. "     ⏰ Trilha \"" .. (tr.name or "") .. "\": Prazo " .. (tr.deadline or "") .. "\n"
                    end
                end
            end
        end
        out = out .. "\n"
    end
    out = out .. "_Consulte o sistema completo para ver todas as trilhas e prazos._"
    return out
end

local function format_members(group_name, members)
    if not members or #members == 0 then
        return "👥 *Equipe — " .. (group_name or "") .. "*\n\nNenhum integrante encontrado."
    end

    local leaders = {}
    local researchers = {}
    local students = {}

    for _, m in ipairs(members) do
        local details = {}
        if m.email and m.email ~= "" then
            table.insert(details, m.email)
        end
        if m.timezone and m.timezone ~= "" then
            table.insert(details, "🕒 " .. m.timezone)
        end
        if m.whatsapp and m.whatsapp ~= "" then
            table.insert(details, "📱 " .. m.whatsapp)
        end

        local display = "• *" .. (m.name or "Sem nome") .. "* (" .. table.concat(details, " | ") .. ")"
        local role = (m.role or ""):lower()
        if role == "leader" or role == "admin" then
            table.insert(leaders, display)
        elseif role == "researcher" then
            table.insert(researchers, display)
        else
            table.insert(students, display)
        end
    end

    local out = "👥 *Integrantes da Equipe — " .. (group_name or "") .. "*\n\n"
    if #leaders > 0 then
        out = out .. "👑 *Liderança:*\n" .. table.concat(leaders, "\n") .. "\n\n"
    end
    if #researchers > 0 then
        out = out .. "🔬 *Pesquisadores:*\n" .. table.concat(researchers, "\n") .. "\n\n"
    end
    if #students > 0 then
        out = out .. "🎓 *Discentes e Alunos:*\n" .. table.concat(students, "\n") .. "\n\n"
    end

    out = out .. "_Total de integrantes: " .. #members .. "_"
    return out
end

local function format_projects(group_name, projects)
    if not projects or #projects == 0 then
        return "📁 *Projetos de Pesquisa — " .. (group_name or "") .. "*\n\nNenhum projeto cadastrado no momento."
    end

    local out = "📁 *Projetos de Pesquisa — " .. (group_name or "") .. "*\n\n"
    local count = math.min(#projects, 6)
    for i = 1, count do
        local p = projects[i]
        local status = p.status or ""
        local status_emoji = "📝 Planejado"
        if status == "active" then
            status_emoji = "🟢 Ativo"
        elseif status == "completed" then
            status_emoji = "✅ Concluído"
        elseif status == "paused" then
            status_emoji = "⏸️ Pausado"
        end

        out = out .. i .. ". *" .. (p.title or "Sem título") .. "* (" .. status_emoji .. ")\n"
        if p.description and p.description ~= "" then
            local desc = p.description
            if #desc > 100 then
                desc = string.sub(desc, 1, 97) .. "..."
            end
            out = out .. "   _" .. desc .. "_\n"
        end
        out = out .. "\n"
    end
    out = out .. "_Total de projetos: " .. #projects .. "_"
    return out
end

local function format_defenses(group_name, defenses)
    if not defenses or #defenses == 0 then
        return "🎓 *Qualificações e Defesas — " .. (group_name or "") .. "*\n\nNenhuma defesa ou banca agendada no momento."
    end

    local out = "🎓 *Qualificações e Defesas — " .. (group_name or "") .. "*\n\n"
    local count = math.min(#defenses, 5)
    for i = 1, count do
        local d = defenses[i]
        local tipo = (d.defense_type == "qualification") and "Qualificação" or "Defesa"
        local level = "Pós-Graduação"
        if d.degree_level == "masters" then
            level = "Mestrado"
        elseif d.degree_level == "doctorate" then
            level = "Doutorado"
        elseif d.degree_level == "undergraduate" then
            level = "TCC / Graduação"
        end

        out = out .. i .. ". *" .. tipo .. " de " .. level .. "* — " .. (d.student or "Discente") .. "\n"
        out = out .. "   🗓️ Data: " .. (d.date or "") .. " às " .. (d.time or "") .. "\n"
        out = out .. "   📝 Título: \"" .. (d.title or "") .. "\"\n"
        if d.advisor and d.advisor ~= "" then
            out = out .. "   👤 Orientador(a): " .. d.advisor .. "\n"
        end
        out = out .. "\n"
    end
    return out
end

local function format_publications(group_name, publications)
    if not publications or #publications == 0 then
        return "📄 *Publicações Científicas — " .. (group_name or "") .. "*\n\nNenhuma publicação cadastrada no momento."
    end

    local out = "📄 *Últimas Publicações — " .. (group_name or "") .. "*\n\n"
    local count = math.min(#publications, 5)
    for i = 1, count do
        local p = publications[i]
        out = out .. i .. ". *" .. (p.title or "") .. "* (" .. (p.year or "") .. ")\n"
        if p.venue and p.venue ~= "" then
            out = out .. "   🏛️ Veículo: " .. p.venue .. "\n"
        end
        if p.authors and p.authors ~= "" then
            out = out .. "   👥 Autores: " .. p.authors .. "\n"
        end
        if p.tags and p.tags ~= "" then
            out = out .. "   🏷️ Tags: " .. p.tags .. "\n"
        end
        out = out .. "\n"
    end
    out = out .. "_Acervo do grupo: " .. #publications .. " publicações registradas._"
    return out
end

local function format_status(group_name)
    return "🤖 *NeoResearch WhatsApp Bot*\n\n" ..
           "🟢 *Status:* Conectado e operacional\n" ..
           "🏢 *Grupo:* " .. (group_name or "Grupo de Pesquisa") .. "\n" ..
           "⚡ *Versão:* v1.0.0 (Plugin Lua Ativo)\n\n" ..
           "Envie *@bot ajuda* para ver a lista de comandos disponíveis."
end

--[[
  Ponto de entrada chamado pelo motor do NeoResearch quando uma mensagem chega.
  Parâmetros em `msg`:
    - msg.text: Texto bruto recebido
    - msg.sender: Número do remetente
    - msg.sender_name: Nome do remetente
    - msg.is_group: Booleano indicando se a mensagem veio de um grupo
    - msg.group_id: ID do grupo de pesquisa no NeoResearch
    - msg.group_name: Nome do grupo de pesquisa
    - msg.members: Lista de integrantes
    - msg.events: Lista de eventos e prazos
    - msg.projects: Lista de projetos de pesquisa
    - msg.publications: Lista de publicações
    - msg.defenses: Lista de bancas e defesas
    - msg.config: Configurações personalizadas definidas pelo usuário
]]
function on_message(msg)
    if not msg or not msg.text then
        return nil
    end

    local raw = msg.text:match("^%s*(.-)%s*$")
    if raw == "" then
        return nil
    end

    local lower = raw:lower()
    local is_explicit_command = false
    local cmd_part = ""

    if lower:sub(1, 4) == "@bot" then
        is_explicit_command = true
        cmd_part = raw:sub(5):match("^%s*(.-)%s*$")
    elseif lower:sub(1, 4) == "!bot" then
        is_explicit_command = true
        cmd_part = raw:sub(5):match("^%s*(.-)%s*$")
    elseif lower:sub(1, 4) == "/bot" then
        is_explicit_command = true
        cmd_part = raw:sub(5):match("^%s*(.-)%s*$")
    else
        -- Em mensagens privadas ou menção direta
        local direct_cmds = {
            ajuda = true, help = true, eventos = true, events = true,
            membros = true, equipe = true, integrantes = true,
            projetos = true, projects = true,
            defesas = true, bancas = true, qualificacoes = true, ["qualificações"] = true,
            publicacoes = true, ["publicações"] = true, artigos = true,
            status = true, info = true, ping = true
        }
        if direct_cmds[lower] then
            cmd_part = raw
        else
            return nil
        end
    end

    local action = cmd_part:match("%S+") or "ajuda"
    action = action:lower()

    if action == "ajuda" or action == "help" or action == "" then
        return format_help(msg.group_name)
    elseif action == "eventos" or action == "events" then
        return format_events(msg.group_name, msg.events)
    elseif action == "membros" or action == "equipe" or action == "integrantes" then
        return format_members(msg.group_name, msg.members)
    elseif action == "projetos" or action == "projects" then
        return format_projects(msg.group_name, msg.projects)
    elseif action == "defesas" or action == "bancas" or action == "qualificacoes" or action == "qualificações" then
        return format_defenses(msg.group_name, msg.defenses)
    elseif action == "publicacoes" or action == "publicações" or action == "artigos" then
        return format_publications(msg.group_name, msg.publications)
    elseif action == "status" or action == "info" or action == "ping" then
        return format_status(msg.group_name)
    elseif is_explicit_command then
        return "❓ Comando *\"" .. action .. "\"* não reconhecido.\n\n" ..
               "Envie *@bot ajuda* para visualizar todos os comandos disponíveis."
    end

    return nil
end
