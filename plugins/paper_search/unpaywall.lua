-- Plugin Unpaywall para NeoResearch
-- Dado um DOI, encontra a versão legal de acesso aberto do artigo (repositórios, editoras, preprints)

plugin = {
    id = "unpaywall",
    name = "Unpaywall (DOI → acesso aberto)",
    version = "1.0.1",
    author = "NeoResearch Community",
    description = "Busca por DOI: devolve os metadados e o PDF legal de acesso aberto do artigo, quando existir (OurResearch/Unpaywall)",
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
    -- A API do Unpaywall só consulta por DOI.
    -- (no modo "auto" também vale: basta a consulta ter cara de DOI)
    local doi = normalize_doi(params.query)
    if not doi:match("^10%.%d+/") then return {} end
    local email = (params.config and params.config.email) or "contato@neoresearch.science"
    local url = "https://api.unpaywall.org/v2/" .. http.url_encode(doi) .. "?email=" .. http.url_encode(email)

    log("Consultando Unpaywall: " .. url)
    local res = http.get(url, { headers = { ["User-Agent"] = UA }, timeout_secs = 12 })
    if not res.ok then
        log("Unpaywall retornou status " .. tostring(res.status))
        return {}
    end
    local w = json.decode(res.body)
    if not T(w) or not S(w.title) then return {} end

    local authors = {}
    for _, a in ipairs(T(w.z_authors) or {}) do
        local name = a.raw_author_name
        if not name and (a.family or a.given) then name = ((a.family or "") .. ", " .. (a.given or "")):gsub(", $", "") end
        if name and #name > 0 then table.insert(authors, name) end
    end
    local pdf = nil
    local loc = w.best_oa_location
    if w.is_oa == true and T(loc) and S(loc.url_for_pdf) then pdf = loc.url_for_pdf end

    log("Unpaywall: " .. (pdf and "PDF aberto encontrado" or "sem PDF aberto"))
    return {{
        doi = normalize_doi(w.doi or doi),
        title = clean_text(w.title),
        authors = authors,
        journal = clean_text(w.journal_name),
        year = tonumber(w.year),
        abstract = nil,
        pdf_url = pdf,
        file_size = nil
    }}
end
