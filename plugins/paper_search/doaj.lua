-- Plugin DOAJ para NeoResearch
-- Directory of Open Access Journals: artigos de periódicos 100% acesso aberto e revisados por pares

plugin = {
    id = "doaj",
    name = "DOAJ (Acesso Aberto)",
    version = "1.0.0",
    author = "NeoResearch Community",
    description = "Artigos de periódicos de acesso aberto revisados por pares indexados no Directory of Open Access Journals",
    target = "paper_search",
    default_enabled = false
}

local UA = "NeoResearch/1.0 (+https://neoresearch.science; mailto:neoresearchglobal@gmail.com)"

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

local function first_doi(bib)
    for _, id in ipairs(T(bib.identifier) or {}) do
        if id.type == "doi" and id.id then return normalize_doi(id.id) end
    end
    return ""
end

local function pdf_link(bib)
    for _, l in ipairs(T(bib.link) or {}) do
        if l.type == "fulltext" and l.url then
            local ct = (l.content_type or ""):upper()
            if ct == "PDF" or l.url:lower():find("%.pdf") then return l.url end
        end
    end
    return nil
end

function search(params)
    local limit, _, page = page_of(params)
    local q = params.query
    if params.search_type == "doi" then
        q = 'bibjson.identifier.id:"' .. normalize_doi(params.query) .. '"'
    end
    local url = "https://doaj.org/api/search/articles/" .. http.url_encode(q)
        .. "?page=" .. tostring(page) .. "&pageSize=" .. tostring(limit)

    log("Consultando DOAJ: " .. url)
    local res = http.get(url, { headers = { ["User-Agent"] = UA }, timeout_secs = 12 })
    if not res.ok then
        log("DOAJ retornou status " .. tostring(res.status))
        return {}
    end
    local data = json.decode(res.body)
    if not data then return {} end

    local results = {}
    for _, item in ipairs(T(data.results) or {}) do
        local bib = T(item.bibjson) or {}
        local authors = {}
        for _, a in ipairs(T(bib.author) or {}) do
            if a.name and #a.name > 0 then table.insert(authors, a.name) end
        end
        table.insert(results, {
            doi = first_doi(bib),
            title = clean_text(bib.title),
            authors = authors,
            journal = T(bib.journal) and clean_text(bib.journal.title) or nil,
            year = tonumber(bib.year),
            abstract = clean_text(bib.abstract),
            pdf_url = pdf_link(bib),
            file_size = nil
        })
    end
    log("DOAJ retornou " .. tostring(#results) .. " artigos")
    return results
end
