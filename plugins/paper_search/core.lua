-- Plugin CORE para NeoResearch
-- Maior agregador mundial de artigos de acesso aberto (milhões de textos completos de repositórios)
-- Requer uma chave gratuita da API: https://core.ac.uk/services/api  (config do plugin: {"api_key": "..."})

plugin = {
    id = "core",
    name = "CORE (Acesso Aberto)",
    version = "1.0.1",
    author = "NeoResearch Community",
    description = "Agregador CORE de artigos em acesso aberto com texto completo (requer chave gratuita da API nas configurações do plugin)",
    target = "paper_search",
    default_enabled = false
}

local UA = "NeoResearch/1.0 (+https://neoresearch.science; mailto:contato@neoresearch.science)"

-- JSON null chega ao Lua como userdata: só aceite o tipo esperado.
local function T(v) if type(v) == "table" then return v end return nil end
local function S(v) if type(v) == "string" and v ~= "" then return v end return nil end

local function normalize_doi(doi)
    if type(doi) ~= "string" then return "" end
    local clean = doi:gsub("^https?://dx%.doi%.org/", ""):gsub("^https?://doi%.org/", "")
    clean = clean:gsub("^doi%.org/", "")
    clean = clean:gsub("^[Dd][Oo][Ii]:", "")
    return clean:match("^%s*(.-)%s*$")
end

-- Remove tags HTML/JATS e decodifica as entidades mais comuns dos resumos.
local function clean_text(s)
    if type(s) ~= "string" then return nil end
    s = s:gsub("<[^>]+>", " ")
    s = s:gsub("&#x(%x+);", function(h) local n = tonumber(h, 16); if n and n < 128 then return string.char(n) end return " " end)
    s = s:gsub("&#(%d+);", function(d) local n = tonumber(d); if n and n < 128 then return string.char(n) end return " " end)
    s = s:gsub("&nbsp;", " "):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", "\""):gsub("&apos;", "\x27"):gsub("&amp;", "&")
    s = s:gsub("%s+", " ")
    s = s:match("^%s*(.-)%s*$")
    if s == "" then return nil end
    return s
end

local function page_of(params)
    local limit = math.max(params.limit or 10, 1)
    local offset = params.offset or 0
    return limit, offset, math.floor(offset / limit) + 1
end

function search(params)
    local api_key = (params.config and params.config.api_key) or ""
    if #api_key == 0 then
        log("CORE: configure a chave da API (api_key) nas configurações do plugin")
        return {}
    end
    local limit, offset = page_of(params)
    local q = params.query
    if params.search_type == "doi" then
        q = 'doi:"' .. normalize_doi(params.query) .. '"'
    end
    local url = "https://api.core.ac.uk/v3/search/works/?q=" .. http.url_encode(q)
        .. "&limit=" .. tostring(limit) .. "&offset=" .. tostring(offset)

    log("Consultando CORE: " .. url)
    local res = http.get(url, {
        headers = { ["User-Agent"] = UA, ["Authorization"] = "Bearer " .. api_key },
        timeout_secs = 15
    })
    if not res.ok then
        log("CORE retornou status " .. tostring(res.status))
        return {}
    end
    local data = json.decode(res.body)
    if not T(data) then return {} end

    local results = {}
    for _, w in ipairs(T(data.results) or {}) do
        local authors = {}
        for _, a in ipairs(T(w.authors) or {}) do
            if a.name and #a.name > 0 then table.insert(authors, a.name) end
        end
        local journal = nil
        if T(w.journals) and T(w.journals[1]) then journal = clean_text(w.journals[1].title) end
        table.insert(results, {
            doi = normalize_doi(w.doi),
            title = clean_text(w.title),
            authors = authors,
            journal = journal or clean_text(w.publisher),
            year = tonumber(w.yearPublished),
            abstract = clean_text(w.abstract),
            pdf_url = S(w.downloadUrl),
            file_size = nil
        })
    end
    log("CORE retornou " .. tostring(#results) .. " artigos")
    return results
end
