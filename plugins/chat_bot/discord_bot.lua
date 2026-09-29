--[[
  NeoResearch Plugin: Discord Bot & Webhooks
  Target: chat_bot
  Integração com canais do Discord via Webhooks e Bot (Discord API v10).
  Permite emissão de Rich Embeds estilizados para publicações, defesas e prazos de conferências.
]]

plugin = {
    id = "discord_bot",
    name = "Discord Bot & Webhooks",
    version = "1.0.0",
    author = "NeoResearch Oficial",
    description = "Integração oficial com Discord via Webhooks com Rich Embeds coloridos para artigos, defesas e eventos do laboratório.",
    target = "chat_bot",
    default_enabled = false,
    ui = {
        type = "tab",
        tab_id = "discord",
        title = "Discord Bot",
        icon = "🎮",
        badge = "Discord",
        tooltip = "Configurar webhooks do Discord para alertas e Rich Embeds",
        settings = {
            {
                key = "webhook_url",
                label = "Webhook URL do Canal",
                type = "url",
                placeholder = "https://discord.com/api/webhooks/...",
                description = "URL do Webhook gerada nas configurações de integração do canal no Discord."
            },
            {
                key = "bot_name",
                label = "Nome de Exibição do Bot",
                type = "text",
                placeholder = "NeoResearch Bot (opcional)",
                description = "Nome que aparecerá no Discord como remetente das mensagens do laboratório."
            },
            {
                key = "avatar_url",
                label = "Avatar URL do Bot",
                type = "url",
                placeholder = "https://exemplo.com/icone.png (opcional)",
                description = "URL da imagem de perfil do bot nas mensagens do Discord."
            }
        },
        guide = {
            title = "Como configurar o Webhook do Discord",
            steps = {
                "Abra o seu servidor no **Discord** e navegue até o canal onde deseja receber as notificações.",
                "Clique no ícone de engrenagem (**Editar Canal**) ao lado do nome do canal.",
                "Acesse a aba **Integrações** e clique em **Criar Webhook** (ou Ver Webhooks).",
                "Personalize o nome do webhook (ex: *NeoResearch Alertas*) e copie a **URL do Webhook**.",
                "Cole a URL no campo de configuração acima e clique em **Salvar Configurações**.",
                "Clique em **Enviar Notificação de Teste** para confirmar a recepção de um Rich Embed no canal."
            },
            commands = {
                { cmd = "Rich Embeds", desc = "Cartões visuais com cores temáticas (Verde: Publicações, Roxo: Defesas, Azul: Eventos)." },
                { cmd = "Alertas em Tempo Real", desc = "Notificações instantâneas de novas bancas agendadas e prazos de submissão." }
            }
        }
    }
}

--[[
  Envia uma mensagem ou Rich Embed para um canal do Discord via Webhook.
]]
local function send_discord_webhook(webhook_url, payload_table)
    if not webhook_url or webhook_url == "" then
        log.warn("Discord Plugin: 'webhook_url' não configurada.")
        return false, "Webhook URL não configurada"
    end

    local payload_json = json.encode(payload_table)
    local res = http.post(webhook_url, {
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = payload_json,
        timeout_secs = 10
    })

    if res.ok or res.status == 204 then
        log.info("Discord: Webhook disparado com sucesso.")
        return true, res.body
    else
        log.error("Discord: Falha no webhook (status " .. res.status .. "): " .. (res.body or res.error or ""))
        return false, res.error or res.body
    end
end

local function format_help(group_name)
    return "🤖 **NeoResearch Discord Assistant**\n" ..
           "🏢 **Laboratório:** " .. (group_name or "Grupo de Pesquisa") .. "\n\n" ..
           "Comandos aceitos no chat:\n" ..
           "• `!bot eventos` ou `@bot eventos` — Prazos de submissão e conferências\n" ..
           "• `!bot membros` ou `@bot membros` — Pesquisadores e alunos do grupo\n" ..
           "• `!bot projetos` ou `@bot projetos` — Projetos em desenvolvimento\n" ..
           "• `!bot defesas` ou `@bot defesas` — Bancas e defesas agendadas\n" ..
           "• `!bot publicações` ou `@bot publicacoes` — Artigos recentes\n" ..
           "• `!bot status` — Status da integração do Discord\n" ..
           "• `!bot teste` — Dispara um cartão Rich Embed de teste no canal configurado"
end

local function format_events(group_name, events)
    if not events or #events == 0 then
        return "📅 **Eventos de Interesse — " .. (group_name or "") .. "**\n\nNenhum evento registrado no momento."
    end

    local out = "📅 **Conferências & Prazos — " .. (group_name or "") .. "**\n\n"
    for i = 1, math.min(#events, 6) do
        local ev = events[i]
        local qualis = (ev.qualis and ev.qualis ~= "") and (" `[Qualis " .. ev.qualis .. "]`") or ""
        out = out .. "**" .. i .. ". " .. (ev.name or "") .. "** (" .. (ev.acronym or "") .. ")" .. qualis .. "\n"

        if ev.occurrences then
            for _, occ in ipairs(ev.occurrences) do
                local date = (occ.date and occ.date ~= "") and occ.date or "A definir"
                out = out .. "  📍 Edição " .. (occ.edition or "") .. " (" .. (occ.city or "") .. " — " .. date .. ")\n"
                if occ.tracks then
                    for _, tr in ipairs(occ.tracks) do
                        out = out .. "    ⏰ Trilha *" .. (tr.name or "") .. "*: Prazo **" .. (tr.deadline or "") .. "**\n"
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
        return "👥 **Integrantes — " .. (group_name or "") .. "**\n\nNenhum integrante cadastrado."
    end

    local out = "👥 **Equipe de Pesquisa — " .. (group_name or "") .. "**\n\n"
    for _, m in ipairs(members) do
        local role = (m.role or ""):lower()
        local badge = (role == "leader" or role == "admin") and "👑 Líder" or ((role == "researcher") and "🔬 Pesquisador" or "🎓 Aluno")
        out = out .. "• **" .. (m.name or "Sem nome") .. "** — " .. badge .. " (`" .. (m.email or "") .. "`)\n"
    end
    return out
end

local function format_projects(group_name, projects)
    if not projects or #projects == 0 then
        return "📁 **Projetos — " .. (group_name or "") .. "**\n\nNenhum projeto registrado."
    end

    local out = "📁 **Projetos de Pesquisa — " .. (group_name or "") .. "**\n\n"
    for i, p in ipairs(projects) do
        local st = (p.status == "active") and "🟢 Ativo" or "📝 " .. (p.status or "Planejado")
        out = out .. "**" .. i .. ". " .. (p.title or "") .. "** (" .. st .. ")\n"
        if p.description and p.description ~= "" then
            out = out .. "> *" .. p.description:sub(1, 95) .. "*\n"
        end
    end
    return out
end

local function format_defenses(group_name, defenses)
    if not defenses or #defenses == 0 then
        return "🎓 **Qualificações e Defesas — " .. (group_name or "") .. "**\n\nNenhuma defesa agendada no momento."
    end

    local out = "🎓 **Qualificações e Defesas Agendadas — " .. (group_name or "") .. "**\n\n"
    for i, d in ipairs(defenses) do
        local tipo = (d.defense_type == "qualification") and "Qualificação" or "Defesa"
        out = out .. "**" .. i .. ". " .. tipo .. "** — " .. (d.student or "Discente") .. "\n"
        out = out .. "🗓️ Data: `" .. (d.date or "") .. " às " .. (d.time or "") .. "`\n"
        out = out .. "📝 Título: *" .. (d.title or "") .. "*\n\n"
    end
    return out
end

local function format_publications(group_name, publications)
    if not publications or #publications == 0 then
        return "📄 **Publicações — " .. (group_name or "") .. "**\n\nNenhuma publicação cadastrada."
    end

    local out = "📄 **Últimas Publicações Científicas — " .. (group_name or "") .. "**\n\n"
    for i = 1, math.min(#publications, 5) do
        local p = publications[i]
        out = out .. "**" .. i .. ". " .. (p.title or "") .. "** (" .. (p.year or "") .. ")\n"
        if p.venue and p.venue ~= "" then out = out .. "🏛️ *" .. p.venue .. "*\n" end
        if p.authors and p.authors ~= "" then out = out .. "👥 " .. p.authors .. "\n" end
        out = out .. "\n"
    end
    return out
end

--[[
  Envia Rich Embeds automáticos quando um evento ocorre no sistema.
]]
function notify(event_type, payload, config)
    config = config or {}
    local webhook_url = config.webhook_url
    if not webhook_url or webhook_url == "" then
        return false, "webhook_url ausente na configuração do plugin Discord."
    end

    local embed = {
        footer = { text = "NeoResearch Scientific Platform" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    if event_type == "new_publication" then
        embed.title = "📢 Nova Publicação Científica Adicionada!"
        embed.color = 5793266 -- #5865F2 (Discord Blurple)
        embed.description = "**" .. (payload.title or "") .. "**"
        embed.fields = {
            { name = "👥 Autores", value = payload.authors or "Equipe", inline = false },
            { name = "🏛️ Veículo", value = (payload.venue or "N/A") .. " (" .. (payload.year or "") .. ")", inline = true },
            { name = "🔗 DOI", value = payload.doi or "N/D", inline = true }
        }
    elseif event_type == "event_deadline" then
        embed.title = "⏰ Alerta de Prazo de Submissão!"
        embed.color = 15548997 -- #ED4245 (Red)
        embed.description = "**" .. (payload.event_name or "") .. "** (" .. (payload.acronym or "") .. ")"
        embed.fields = {
            { name = "🎯 Trilha", value = payload.track_name or "Principal", inline = true },
            { name = "🗓️ Prazo Final", value = payload.deadline or "N/D", inline = true }
        }
    elseif event_type == "defense_scheduled" then
        embed.title = "🎓 Nova Defesa / Qualificação Agendada"
        embed.color = 10181046 -- #9B59B6 (Purple)
        embed.description = "**" .. (payload.title or "") .. "**"
        embed.fields = {
            { name = "👤 Discente", value = payload.student or "N/D", inline = true },
            { name = "🗓️ Data e Hora", value = (payload.date or "") .. " às " .. (payload.time or ""), inline = true },
            { name = "👥 Orientador(a)", value = payload.advisor or "N/D", inline = false }
        }
    else
        embed.title = "🔔 Notificação do Laboratório"
        embed.color = 3447003 -- #3498DB (Blue)
        embed.description = payload.message or "Novo aviso cadastrado."
    end

    local body = {
        username = config.bot_username or "NeoResearch Bot",
        avatar_url = config.avatar_url or "https://neoresearch.app/static/img/logo_icone.png",
        embeds = { embed }
    }

    return send_discord_webhook(webhook_url, body)
end

--[[
  Processamento de mensagens ou comandos.
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
    local webhook_url = config.webhook_url or ""

    local lower = raw:lower()
    local cmd = ""

    if lower:sub(1, 4) == "@bot" or lower:sub(1, 4) == "!bot" or lower:sub(1, 4) == "/bot" then
        cmd = lower:sub(5):match("%S+") or ""
    else
        cmd = lower:match("%S+") or ""
    end

    if cmd == "ajuda" or cmd == "help" then
        return format_help(msg.group_name)
    elseif cmd == "eventos" or cmd == "events" then
        return format_events(msg.group_name, msg.events)
    elseif cmd == "membros" or cmd == "equipe" then
        return format_members(msg.group_name, msg.members)
    elseif cmd == "projetos" or cmd == "projects" then
        return format_projects(msg.group_name, msg.projects)
    elseif cmd == "defesas" or cmd == "bancas" then
        return format_defenses(msg.group_name, msg.defenses)
    elseif cmd == "publicacoes" or cmd == "artigos" or cmd == "publicações" then
        return format_publications(msg.group_name, msg.publications)
    elseif cmd == "status" or cmd == "info" then
        local url_status = (webhook_url ~= "") and "🟢 Webhook Configurado" or "🔴 Webhook Não Configurado"
        return "🤖 **Status da Integração Discord**\n\n" ..
               "🏢 **Laboratório:** " .. (msg.group_name or "") .. "\n" ..
               "🔗 **Webhook URL:** " .. url_status .. "\n" ..
               "⚡ **Versão:** v1.0.0\n\n" ..
               "_Edite a configuração deste plugin para definir a URL do canal do Discord._"
    elseif cmd == "teste" or cmd == "test" then
        if webhook_url == "" then
            return "⚠️ **Discord Bot**: A `webhook_url` precisa estar configurada nas opções do plugin para disparar mensagens no Discord."
        end

        local embed = {
            title = "🧪 Teste de Conexão com o Discord",
            description = "O plugin Lua **Discord Bot & Webhooks** foi executado com sucesso no NeoResearch!",
            color = 3066993, -- #2ECC71 (Green)
            fields = {
                { name = "🏢 Grupo de Pesquisa", value = msg.group_name or "NeoResearch Lab", inline = true },
                { name = "⚡ Status", value = "Conectado e Operacional", inline = true }
            },
            footer = { text = "NeoResearch • Notificações Acadêmicas" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }

        local ok, detail = send_discord_webhook(webhook_url, {
            username = config.bot_username or "NeoResearch Bot",
            embeds = { embed }
        })

        if ok then
            return "✅ **Disparo de Teste Realizado**: O Rich Embed de teste foi enviado ao Discord com sucesso!"
        else
            return "❌ **Falha ao Enviar Webhook**: " .. tostring(detail)
        end
    end

    if lower:sub(1, 4) == "@bot" or lower:sub(1, 4) == "!bot" or lower:sub(1, 4) == "/bot" then
        return "❓ Comando `!" .. cmd .. "` não reconhecido.\nEnvie `!bot ajuda` para ver os comandos."
    end

    return nil
end
