--[[
  NeoResearch Plugin: Rádio Global & Lofi Ambient (Modal/Widget Flutuante)
  Target: media
  Tipo de Interface: floating (Widget/Player Flutuante na tela com persistência)

  Player de áudio em segundo plano permitindo escutar emissoras do Brasil (inclusive de
  Salvador-BA) e do mundo, canais de lofi/foco, ambient, música clássica e jazz, com
  controle de reprodução e visualizador de ondas rítmicas.

  ESTE ARQUIVO É AUTOCONTIDO: as categorias e as estações abaixo são a ÚNICA fonte de
  dados do player. O front-end (static/js/app.js) não tem nenhuma lista própria: ele lê
  `ui.categories` e `ui.stations` deste manifesto. Para adicionar, remover ou trocar uma
  rádio, edite só este script (no gerenciador de plugins ou no arquivo).

  Regras para uma estação entrar (verificadas em 2026-09-29):
    * o stream precisa ser https (o site é https; http seria bloqueado como conteúdo misto);
    * o servidor do stream precisa enviar CORS (Access-Control-Allow-Origin) em TODOS os
      saltos de redirecionamento, porque o player usa Web Audio para o visualizador;
    * precisa responder 200 com áudio de verdade (MP3/AAC/OGG), sem HLS (.m3u8).
  Campos de cada estação: id (único), name, category (um dos ids de `categories`),
  country (bandeira + cidade/região), genre, description, icon (emoji) e url.
--]]

plugin = {
    id = "world_radio",
    name = "Rádio Global & Lofi Ambient",
    version = "1.1.0",
    author = "NeoResearch Media",
    description = "Player flutuante de rádio ao vivo com estações do Brasil (inclusive Salvador-BA) e do mundo, lofi/foco, ambient, clássica e jazz, com visualizador de ondas rítmicas. A lista de estações vive neste script.",
    target = "media",
    default_enabled = true,
    ui = {
        type = "floating", -- Tipo de UI para plugins flutuantes
        modal_id = "world-radio-player",
        title = "Rádio Global & Lofi",
        icon = "📻",
        badge = "Ao Vivo",
        tooltip = "Player de Rádio Flutuante - Música para Estudos e Trabalho",
        dock_position = "bottom-right",
        categories = {
            { id = "brazil", label = "🇧🇷 Brasil" },
            { id = "lofi", label = "🎧 Lofi / Estudo" },
            { id = "ambient", label = "🌌 Ambient" },
            { id = "classical", label = "🎻 Clássica" },
            { id = "jazz", label = "🎷 Jazz" }
        },
        stations = {
            -- ===== Brasil (inclui rádios de Salvador-BA) =====
            {
                id = "jbfm",
                name = "JB FM 99.9",
                category = "brazil",
                country = "🇧🇷 Rio de Janeiro",
                genre = "Adult Contemporary & MPB",
                description = "Adult contemporary e MPB, direto do Rio de Janeiro",
                icon = "📻",
                url = "https://playerservices.streamtheworld.com/api/livestream-redirect/JBFMAAC.aac"
            },
            {
                id = "alphafm",
                name = "Alpha FM 101.7",
                category = "brazil",
                country = "🇧🇷 São Paulo",
                genre = "Pop, Rock & MPB",
                description = "Pop, rock e MPB internacional",
                icon = "🏙️",
                url = "https://playerservices.streamtheworld.com/api/livestream-redirect/RADIO_ALPHAFMAAC.aac"
            },
            {
                id = "antena1_sp",
                name = "Antena 1 94.7",
                category = "brazil",
                country = "🇧🇷 São Paulo",
                genre = "Adult Contemporary",
                description = "Clássicos internacionais e música para relaxar",
                icon = "🗼",
                url = "https://antenaone.crossradio.com.br/stream/1/"
            },
            {
                id = "saudade_fm",
                name = "Rádio Saudade FM 99.7",
                category = "brazil",
                country = "🇧🇷 Santos-SP",
                genre = "Flashback & Clássicos",
                description = "Sucessos que marcaram época",
                icon = "🕰️",
                url = "https://playerservices.streamtheworld.com/api/livestream-redirect/SAUDADE_FMAAC.aac"
            },
            {
                id = "nova_brasil",
                name = "Nova Brasil FM",
                category = "brazil",
                country = "🇧🇷 São Paulo",
                genre = "MPB & Soul",
                description = "MPB, soul e música brasileira contemporânea",
                icon = "🥁",
                url = "https://playerservices.streamtheworld.com/api/livestream-redirect/NOVABRASIL_SPAAC.aac"
            },
            {
                id = "radio_89_rock",
                name = "89 A Rádio Rock",
                category = "brazil",
                country = "🇧🇷 São Paulo",
                genre = "Rock",
                description = "Rock clássico e alternativo",
                icon = "🎸",
                url = "https://playerservices.streamtheworld.com/api/livestream-redirect/RADIO_89FM_ADP.aac?dist=site-89fm"
            },
            {
                id = "cidade_rj",
                name = "Rádio Cidade 102.9",
                category = "brazil",
                country = "🇧🇷 Rio de Janeiro",
                genre = "Rock & Pop",
                description = "Rock e pop no coração do Rio",
                icon = "🌆",
                url = "https://playerservices.streamtheworld.com/api/livestream-redirect/RADIOCIDADEAAC.aac"
            },
            {
                id = "joli_mpb",
                name = "Rádio Joli MPB",
                category = "brazil",
                country = "🇧🇷 Nacional",
                genre = "MPB",
                description = "MPB 24 horas",
                icon = "🎶",
                url = "https://stream-163.zeno.fm/mrutsyhkc3quv"
            },
            {
                id = "gfm_salvador",
                name = "GFM Salvador 90.1",
                category = "brazil",
                country = "🇧🇷 Salvador-BA",
                genre = "Adult Contemporary & MPB",
                description = "Música brasileira e adult contemporary na capital baiana",
                icon = "🌴",
                url = "https://ice-br.fabricahost.com.br/play/radiogfm"
            },
            {
                id = "bahia_fm",
                name = "Bahia FM 88.7",
                category = "brazil",
                country = "🇧🇷 Salvador-BA",
                genre = "Música Brasileira",
                description = "Axé, pagode e os sucessos da Bahia",
                icon = "🥁",
                url = "https://ice-br.fabricahost.com.br/play/radiobahiafm"
            },
            {
                id = "jovem_pan_salvador",
                name = "Jovem Pan FM Salvador 91.3",
                category = "brazil",
                country = "🇧🇷 Salvador-BA",
                genre = "Pop & Hits",
                description = "Hits nacionais e internacionais na capital baiana",
                icon = "🔥",
                url = "https://shout25.crossradio.com.br:18022/1"
            },
            {
                id = "itapoan_fm",
                name = "Rádio Itapoan FM 97.5",
                category = "brazil",
                country = "🇧🇷 Salvador-BA",
                genre = "Axé & Pagode",
                description = "A rádio do axé e da cultura baiana",
                icon = "🏖️",
                url = "https://cast.radiu.live:9300/stream"
            },
            -- ===== 🎧 Lofi / Estudo =====
            {
                id = "lofi_brasil",
                name = "Lofi Brasil & MPB Chill",
                category = "lofi",
                country = "🇧🇷 Foco & Estudo",
                genre = "Lofi & MPB Chill",
                description = "Beats calmos para estudar e programar",
                icon = "🎧",
                url = "https://stream.zeno.fm/f3wvbbqmdg8uv"
            },
            {
                id = "reyfm_lofi",
                name = "REYFM Lo-Fi",
                category = "lofi",
                country = "🇩🇪 Lo-Fi 24h",
                genre = "Lo-Fi Hip Hop",
                description = "Lo-fi hip hop em alta qualidade (320 kbps)",
                icon = "☕",
                url = "https://listen.reyfm.de/lofi_320kbps.mp3"
            },
            {
                id = "nia_lofi",
                name = "NIA Radio Lo-Fi",
                category = "lofi",
                country = "🌐 Lo-Fi",
                genre = "Lo-Fi",
                description = "Batidas lo-fi para concentração",
                icon = "🌙",
                url = "https://radio.nia.nc/radio/8020/lofi-hq-stream.aac"
            },
            {
                id = "ilove_chillhop",
                name = "I Love Chillhop",
                category = "lofi",
                country = "🇩🇪 Chillhop",
                genre = "Chillhop",
                description = "Chillhop e jazzhop para trabalhar com calma",
                icon = "🍃",
                url = "https://ilm.stream12.radiohost.de/ilm_ilovechillhop_mp3-192"
            },
            {
                id = "bigfm_lofifocus",
                name = "bigFM LoFi Focus",
                category = "lofi",
                country = "🇩🇪 Foco",
                genre = "Lo-Fi Focus",
                description = "Lo-fi para foco profundo",
                icon = "🧠",
                url = "https://stream.bigfm.de/lofifocus/mp3-128/radiobrowser"
            },
            {
                id = "nightwave_plaza",
                name = "Nightwave Plaza",
                category = "lofi",
                country = "🌐 Vaporwave",
                genre = "Vaporwave & City Pop",
                description = "Vaporwave, synthwave e city pop",
                icon = "🌴",
                url = "https://radio.plaza.one/mp3"
            },
            {
                id = "soma_defcon",
                name = "SomaFM DEF CON Radio",
                category = "lofi",
                country = "🇺🇸 Hacking Beats",
                genre = "Electro & Coding",
                description = "Música para hackers e programadores",
                icon = "💻",
                url = "https://ice1.somafm.com/defcon-128-mp3"
            },
            -- ===== 🌌 Ambient =====
            {
                id = "soma_groovesalad",
                name = "SomaFM Groove Salad",
                category = "ambient",
                country = "🇺🇸 San Francisco",
                genre = "Downtempo & Ambient",
                description = "Downtempo e ambient groove para foco",
                icon = "🥗",
                url = "https://ice1.somafm.com/groovesalad-128-mp3"
            },
            {
                id = "soma_dronezone",
                name = "SomaFM Drone Zone",
                category = "ambient",
                country = "🇺🇸 Deep Focus",
                genre = "Ambient & Drone",
                description = "Texturas etéreas para concentração máxima",
                icon = "🌌",
                url = "https://ice1.somafm.com/dronezone-128-mp3"
            },
            {
                id = "soma_deepspaceone",
                name = "SomaFM Deep Space One",
                category = "ambient",
                country = "🇺🇸 Ambient Espacial",
                genre = "Deep Ambient",
                description = "Ambient profundo e eletrônica espacial",
                icon = "🚀",
                url = "https://ice1.somafm.com/deepspaceone-128-mp3"
            },
            {
                id = "soma_spacestation",
                name = "SomaFM Space Station Soma",
                category = "ambient",
                country = "🇺🇸 Space Ambient",
                genre = "Space Electronica",
                description = "Eletrônica espacial e ambient",
                icon = "🛰️",
                url = "https://ice1.somafm.com/spacestation-128-mp3"
            },
            {
                id = "soma_missioncontrol",
                name = "SomaFM Mission Control",
                category = "ambient",
                country = "🇺🇸 Missões Espaciais",
                genre = "Ambient & Comunicações NASA",
                description = "Ambient com comunicações reais de missões espaciais",
                icon = "🎙️",
                url = "https://ice1.somafm.com/missioncontrol-128-mp3"
            },
            {
                id = "soma_synphaera",
                name = "SomaFM Synphaera",
                category = "ambient",
                country = "🇺🇸 Ambient Espacial",
                genre = "Ambient Espacial",
                description = "Sons do futuro e ambient espacial",
                icon = "🪐",
                url = "https://ice1.somafm.com/synphaera-128-mp3"
            },
            {
                id = "soma_lush",
                name = "SomaFM Lush",
                category = "ambient",
                country = "🇺🇸 Dream Pop",
                genre = "Dream Pop & Chill",
                description = "Vocais suaves e dream pop",
                icon = "✨",
                url = "https://ice1.somafm.com/lush-128-mp3"
            },
            {
                id = "soma_suburbs",
                name = "SomaFM Suburbs of Goa",
                category = "ambient",
                country = "🇮🇳 World Chill",
                genre = "World Chill",
                description = "Fusão asiática e world ambient",
                icon = "🪕",
                url = "https://ice1.somafm.com/suburbsofgoa-128-mp3"
            },
            {
                id = "nature_sleep",
                name = "Nature Radio Sleep",
                category = "ambient",
                country = "🇮🇹 Sons da Natureza",
                genre = "Sons da Natureza",
                description = "Chuva, floresta e sons da natureza para relaxar e dormir",
                icon = "🌿",
                url = "https://az1.mediacp.eu/listen/natureradiosleep/radio.mp3"
            },
            -- ===== 🎻 Clássica =====
            {
                id = "france_musique",
                name = "France Musique",
                category = "classical",
                country = "🇫🇷 Paris",
                genre = "Clássica",
                description = "Música clássica e erudita 24h da Radio France",
                icon = "🎻",
                url = "https://icecast.radiofrance.fr/francemusique-midfi.mp3"
            },
            {
                id = "france_opera",
                name = "France Musique Opéra",
                category = "classical",
                country = "🇫🇷 Paris",
                genre = "Ópera",
                description = "Ópera e canto lírico",
                icon = "🎭",
                url = "https://icecast.radiofrance.fr/francemusiqueopera-hifi.aac"
            },
            {
                id = "mpr_chamber",
                name = "Your Classical Chamber Music",
                category = "classical",
                country = "🇺🇸 Minnesota",
                genre = "Música de Câmara",
                description = "Música de câmara da Minnesota Public Radio",
                icon = "🎼",
                url = "https://chambermusic.stream.publicradio.org/chambermusic.mp3"
            },
            {
                id = "mpr_piano",
                name = "MPR Classical Piano",
                category = "classical",
                country = "🇺🇸 Minnesota",
                genre = "Piano Clássico",
                description = "Piano clássico tranquilo",
                icon = "🎹",
                url = "https://holiday.stream.publicradio.org/peacefulpiano.mp3"
            },
            {
                id = "whisperings_piano",
                name = "Whisperings Solo Piano",
                category = "classical",
                country = "🇺🇸 Oregon",
                genre = "Piano Solo",
                description = "Piano solo contemplativo",
                icon = "🎹",
                url = "https://pianosolo.streamguys1.com/live"
            },
            {
                id = "epic_orchestral",
                name = "Epic Classical Orchestral",
                category = "classical",
                country = "🇩🇪 Orquestral",
                genre = "Orquestral",
                description = "Grandes obras orquestrais",
                icon = "🎺",
                url = "https://stream.epic-classical.com/classical-orchestral"
            },
            {
                id = "epic_piano",
                name = "Epic Classical Piano",
                category = "classical",
                country = "🇩🇪 Piano",
                genre = "Piano Clássico",
                description = "Peças clássicas para piano",
                icon = "🎹",
                url = "https://stream.epic-classical.com/classical-piano"
            },
            {
                id = "beethoven",
                name = "Beethoven",
                category = "classical",
                country = "🇩🇪 Compositor",
                genre = "Beethoven",
                description = "Apenas Beethoven, 24 horas",
                icon = "🎶",
                url = "https://stream.0nlineradio.com/beethoven"
            },
            -- ===== 🎷 Jazz =====
            {
                id = "fip",
                name = "FIP Paris",
                category = "jazz",
                country = "🇫🇷 Eclética & Jazz",
                genre = "Jazz, Funk & Soul",
                description = "Jazz, funk, soul e grooves franceses",
                icon = "🎷",
                url = "https://icecast.radiofrance.fr/fip-midfi.mp3"
            },
            {
                id = "soma_secretagent",
                name = "SomaFM Secret Agent",
                category = "jazz",
                country = "🇺🇸 Spy Lounges",
                genre = "Lounge & Espionagem",
                description = "Trilhas de espionagem e lounge dos anos 60",
                icon = "🍸",
                url = "https://ice1.somafm.com/secretagent-128-mp3"
            },
            {
                id = "adroit_jazz",
                name = "Adroit Jazz Underground",
                category = "jazz",
                country = "🇺🇸 Jazz",
                genre = "Jazz",
                description = "Jazz de alta qualidade (320 kbps)",
                icon = "🎺",
                url = "https://icecast.walmradio.com:8443/jazz"
            },
            {
                id = "smoothjazz_com",
                name = "SmoothJazz.com",
                category = "jazz",
                country = "🇺🇸 Smooth Jazz",
                genre = "Smooth Jazz",
                description = "O smooth jazz clássico",
                icon = "🌇",
                url = "https://smoothjazz.cdnstream1.com/2585_128.mp3"
            },
            {
                id = "bossa_jazz_brasil",
                name = "Bossa Jazz Brasil",
                category = "jazz",
                country = "🇧🇷 Bossa Nova",
                genre = "Bossa Nova & Jazz",
                description = "Bossa nova e jazz brasileiro",
                icon = "🌴",
                url = "https://centova5.transmissaodigital.com:20104/live"
            },
            {
                id = "smooth_jazz_lounge",
                name = "Smooth Jazz Lounge",
                category = "jazz",
                country = "🇧🇷 Lounge",
                genre = "Smooth Jazz Lounge",
                description = "Smooth jazz para relaxar",
                icon = "🥂",
                url = "https://radio4.vip-radios.fm:18060/stream-128kmp3-SmoothJazzLounge"
            },
            {
                id = "tropical_jazz",
                name = "Tropical Smooth Jazz",
                category = "jazz",
                country = "🇧🇷 Tropical",
                genre = "Smooth Jazz Tropical",
                description = "Smooth jazz com clima tropical",
                icon = "🏝️",
                url = "https://servidor32-3.brlogic.com:8230/live"
            },
            {
                id = "on_jazz",
                name = "0N Jazz on Radio",
                category = "jazz",
                country = "🇩🇪 Jazz",
                genre = "Jazz",
                description = "Jazz clássico e moderno",
                icon = "🎷",
                url = "https://0n-jazz.radionetz.de/0n-jazz.mp3"
            },
            {
                id = "epic_lounge",
                name = "Epic Lounge Piano & Jazz Bar",
                category = "jazz",
                country = "🇩🇪 Piano Bar",
                genre = "Piano Jazz",
                description = "Piano e jazz de bar",
                icon = "🍷",
                url = "https://stream.epic-lounge.com/piano-jazz-bar"
            }
        },
        settings = {
            {
                key = "default_station",
                label = "Estação Padrão",
                type = "select",
                default = "jbfm",
                description = "Estação sintonizada inicialmente ao carregar a aplicação."
            },
            {
                key = "initial_volume",
                label = "Volume Inicial (0 a 100%)",
                type = "number",
                default = "70",
                description = "Nível de volume padrão do player de áudio."
            }
        },
        guide = {
            title = "Como utilizar o Player de Rádio Flutuante",
            steps = {
                "O player de rádio flutuante acompanha sua navegação em todas as abas do sistema sem interrupções.",
                "Utilize os botões **Play**, **Pause** e **Stop** para controlar a reprodução do streaming ao vivo.",
                "As barras do **Equalizador Visual** reagem dinamicamente à música enquanto o áudio estiver tocando.",
                "Clique no botão de **Minimizar** para transformar o player em uma barra compacta no canto inferior da tela.",
                "Você pode pesquisar estações pelo nome, gênero ou cidade (ex.: **Salvador**), ou filtrar pelas categorias rápidas.",
                "Adicione transmissões de rádio personalizadas colando uma URL https direta de áudio (MP3 ou AAC) cujo servidor permita CORS.",
                "Para mudar a lista de estações, edite o script deste plugin: ele é a única fonte da lista."
            }
        }
    }
}

-- Função de busca para integração com a sandbox do gerenciador de testes
function search(params)
    local query = string.lower(params.query or "")
    log.info("Consultando estações da Rádio Global para o termo: " .. query)

    local results = {}
    if plugin.ui and plugin.ui.stations then
        for _, st in ipairs(plugin.ui.stations) do
            local match = query == ""
                or string.find(string.lower(st.name or ""), query, 1, true)
                or string.find(string.lower(st.genre or ""), query, 1, true)
                or string.find(string.lower(st.country or ""), query, 1, true)
                or string.find(string.lower(st.category or ""), query, 1, true)

            if match then
                table.insert(results, {
                    title = (st.icon or "📻") .. " " .. (st.name or "Rádio") .. " (" .. (st.country or "Global") .. ")",
                    authors = st.genre or "Streaming Ao Vivo",
                    venue = "Rádio Online (" .. (st.category or "música") .. ")",
                    year = 2026,
                    abstract = (st.description or "Transmissão ao vivo de áudio.") .. " [Stream URL: " .. (st.url or "") .. "]",
                    landing_page = st.url or "",
                    pdf_url = nil
                })
            end
        end
    end

    return results
end
