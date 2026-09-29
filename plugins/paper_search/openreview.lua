-- Plugin OpenReview para NeoResearch
-- Artigos de conferências de aprendizado de máquina (NeurIPS, ICLR, ICML...) com PDFs abertos

plugin = {
    id = "openreview",
    name = "OpenReview",
    version = "1.0.0",
    author = "NeoResearch Community",
    description = "Artigos submetidos e aceitos em conferências e workshops de IA/ML publicados abertamente no OpenReview",
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

-- A API v1 devolve o valor direto; a v2 devolve { value = ... }.
local function val(v)
    if type(v) == "table" and v.value ~= nil then return v.value end
    return v
end

function search(params)
    if params.search_type == "doi" then return {} end
    local limit, offset = page_of(params)
    local url = "https://api.openreview.net/notes/search?term=" .. http.url_encode(params.query)
        .. "&source=forum&limit=" .. tostring(limit) .. "&offset=" .. tostring(offset)

    log("Consultando OpenReview: " .. url)
    local res = http.get(url, { headers = { ["User-Agent"] = UA }, timeout_secs = 12 })
    if not res.ok then
        log("OpenReview retornou status " .. tostring(res.status))
        return {}
    end
    local data = json.decode(res.body)
    if not T(data) then return {} end

    local results = {}
    for _, n in ipairs(T(data.notes) or {}) do
        local c = T(n.content) or {}
        local title = clean_text(val(c.title))
        if title then
            local authors = val(c.authors)
            if type(authors) ~= "table" then authors = {} end
            local pdf = val(c.pdf)
            local pdf_url = nil
            if type(pdf) == "string" and #pdf > 0 then
                if pdf:sub(1, 4) == "http" then pdf_url = pdf else pdf_url = "https://openreview.net" .. pdf end
            end
            local year = nil
            if type(n.cdate) == "number" then year = tonumber(os.date("!%Y", math.floor(n.cdate / 1000))) end
            local abstract = clean_text(val(c.abstract))
            table.insert(results, {
                doi = "",
                title = title,
                authors = authors,
                journal = clean_text(val(c.venue)),
                year = year,
                abstract = abstract,
                pdf_url = pdf_url,
                file_size = nil
            })
        end
    end
    log("OpenReview retornou " .. tostring(#results) .. " artigos")
    return results
end
