-- Plugin HAL para NeoResearch
-- Arquivo aberto nacional francês (CNRS/INRIA/universidades): artigos, teses, preprints e conferências

plugin = {
    id = "hal",
    name = "HAL (França)",
    version = "1.0.0",
    author = "NeoResearch Community",
    description = "Arquivo aberto HAL (CNRS, Inria e universidades francesas) com artigos, teses e trabalhos de conferências",
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

local function first(v)
    if type(v) == "table" then return v[1] end
    return v
end

function search(params)
    local limit, offset = page_of(params)
    local q = params.query
    if params.search_type == "doi" then
        q = 'doiId_s:"' .. normalize_doi(params.query) .. '"'
    end
    local url = "https://api.hal.science/search/?q=" .. http.url_encode(q)
        .. "&rows=" .. tostring(limit) .. "&start=" .. tostring(offset)
        .. "&wt=json&fl=" .. http.url_encode("title_s,authFullName_s,doiId_s,producedDateY_i,fileMain_s,abstract_s,journalTitle_s,conferenceTitle_s,bookTitle_s")

    log("Consultando HAL: " .. url)
    local res = http.get(url, { headers = { ["User-Agent"] = UA }, timeout_secs = 12 })
    if not res.ok then
        log("HAL retornou status " .. tostring(res.status))
        return {}
    end
    local data = json.decode(res.body)
    if not T(data) or not T(data.response) then return {} end

    local results = {}
    for _, d in ipairs(T(data.response.docs) or {}) do
        local venue = first(d.journalTitle_s) or first(d.conferenceTitle_s) or first(d.bookTitle_s)
        table.insert(results, {
            doi = normalize_doi(d.doiId_s),
            title = clean_text(first(d.title_s)),
            authors = T(d.authFullName_s) or {},
            journal = clean_text(venue),
            year = tonumber(d.producedDateY_i),
            abstract = clean_text(first(d.abstract_s)),
            pdf_url = S(d.fileMain_s),
            file_size = nil
        })
    end
    log("HAL retornou " .. tostring(#results) .. " documentos")
    return results
end
