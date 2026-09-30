-- Plugin Zenodo para NeoResearch
-- Repositório aberto do CERN/OpenAIRE: artigos, preprints, relatórios e teses depositados por pesquisadores

plugin = {
    id = "zenodo",
    name = "Zenodo",
    version = "1.0.1",
    author = "NeoResearch Community",
    description = "Publicações, preprints, relatórios e teses depositados no repositório aberto Zenodo (só arquivos de acesso aberto)",
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

local function open_pdf(rec)
    local md = T(rec.metadata) or {}
    if md.access_right ~= "open" then return nil end
    for _, f in ipairs(T(rec.files) or {}) do
        local key = (f.key or ""):lower()
        if key:match("%.pdf$") and T(f.links) and S(f.links.self) then return f.links.self end
    end
    return nil
end

function search(params)
    local limit, _, page = page_of(params)
    local q = params.query
    if params.search_type == "doi" then
        q = 'doi:"' .. normalize_doi(params.query) .. '"'
    end
    local url = "https://zenodo.org/api/records?q=" .. http.url_encode(q)
        .. "&type=publication&size=" .. tostring(limit) .. "&page=" .. tostring(page)

    log("Consultando Zenodo: " .. url)
    local res = http.get(url, { headers = { ["User-Agent"] = UA }, timeout_secs = 12 })
    if not res.ok then
        log("Zenodo retornou status " .. tostring(res.status))
        return {}
    end
    local data = json.decode(res.body)
    if not T(data) or not T(data.hits) then return {} end

    local results = {}
    for _, rec in ipairs(T(data.hits.hits) or {}) do
        local md = T(rec.metadata) or {}
        local authors = {}
        for _, c in ipairs(T(md.creators) or {}) do
            if c.name and #c.name > 0 then table.insert(authors, c.name) end
        end
        local year = nil
        if S(md.publication_date) then year = tonumber(md.publication_date:match("^(%d%d%d%d)")) end
        table.insert(results, {
            doi = normalize_doi(rec.doi or md.doi),
            title = clean_text(md.title),
            authors = authors,
            journal = T(md.journal) and clean_text(md.journal.title) or nil,
            year = year,
            abstract = clean_text(md.description),
            pdf_url = open_pdf(rec),
            file_size = nil
        })
    end
    log("Zenodo retornou " .. tostring(#results) .. " registros")
    return results
end
