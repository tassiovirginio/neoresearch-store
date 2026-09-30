-- Plugin OpenAIRE para NeoResearch
-- Grafo europeu de produtos de pesquisa (publicações, com indicação de acesso aberto)

plugin = {
    id = "openaire",
    name = "OpenAIRE",
    version = "1.0.1",
    author = "NeoResearch Community",
    description = "Publicações do grafo de pesquisa europeu OpenAIRE, com identificação de acesso aberto",
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

local function pid_of(item, scheme)
    for _, p in ipairs(T(item.pids) or {}) do
        if p.scheme == scheme and p.value then return p.value end
    end
    return nil
end

local function pdf_of(item)
    if T(item.bestAccessRight) and item.bestAccessRight.label ~= "OPEN" then return nil end
    for _, inst in ipairs(T(item.instances) or {}) do
        for _, u in ipairs(T(inst.urls) or {}) do
            if type(u) == "string" and u:lower():find("%.pdf") then return u end
        end
    end
    return nil
end

function search(params)
    local limit, _, page = page_of(params)
    local url = "https://api.openaire.eu/graph/v1/researchProducts?type=publication&pageSize=" .. tostring(limit)
        .. "&page=" .. tostring(page)
    if params.search_type == "doi" then
        url = url .. "&pid=" .. http.url_encode(normalize_doi(params.query))
    else
        url = url .. "&search=" .. http.url_encode(params.query)
    end

    log("Consultando OpenAIRE: " .. url)
    local res = http.get(url, { headers = { ["User-Agent"] = UA }, timeout_secs = 15 })
    if not res.ok then
        log("OpenAIRE retornou status " .. tostring(res.status))
        return {}
    end
    local data = json.decode(res.body)
    if not T(data) then return {} end

    local results = {}
    for _, item in ipairs(T(data.results) or {}) do
        local authors = {}
        for _, a in ipairs(T(item.authors) or {}) do
            if a.fullName and #a.fullName > 0 then table.insert(authors, a.fullName) end
        end
        local year = nil
        if S(item.publicationDate) then year = tonumber(item.publicationDate:match("^(%d%d%d%d)")) end
        local descriptions = item.descriptions
        table.insert(results, {
            doi = normalize_doi(pid_of(item, "doi")),
            title = clean_text(item.mainTitle),
            authors = authors,
            journal = (T(item.container) and clean_text(item.container.name)) or clean_text(item.publisher),
            year = year,
            abstract = T(descriptions) and clean_text(descriptions[1]) or nil,
            pdf_url = pdf_of(item),
            file_size = nil
        })
    end
    log("OpenAIRE retornou " .. tostring(#results) .. " publicações")
    return results
end
