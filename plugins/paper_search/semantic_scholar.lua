-- Plugin Semantic Scholar para NeoResearch
-- Motor de busca baseado em IA do Allen Institute for AI

plugin = {
    id = "semantic_scholar",
    name = "Semantic Scholar",
    version = "1.0.0",
    author = "NeoResearch",
    description = "Busca semântica com suporte a inteligência artificial (requer chave opcional para alto volume)",
    target = "paper_search",
    default_enabled = false
}

local function normalize_doi(doi)
    if not doi then return "" end
    local clean = doi:gsub("^https?://doi%.org/", "")
    clean = clean:gsub("^doi%.org/", "")
    clean = clean:gsub("^[Dd][Oo][Ii]:", "")
    return clean:match("^%s*(.-)%s*$")
end

local function extract_authors(paper_authors)
    local authors = {}
    if not paper_authors then return authors end
    for _, a in ipairs(paper_authors) do
        if a.name and #a.name > 0 then
            table.insert(authors, a.name)
        end
    end
    return authors
end

function search(params)
    local base_url = "https://api.semanticscholar.org/graph/v1/paper"
    local fields = "title,year,authors,externalIds,openAccessPdf,abstract,venue"
    local headers = {
        ["User-Agent"] = "NeoResearch/1.0 (+https://github.com/tassiovirginio/colabpesquisa)"
    }

    -- Suporte a API key via configuração do plugin
    local api_key = (params.config and params.config.api_key) or ""
    if #api_key > 0 then
        headers["x-api-key"] = api_key
    end

    local url = ""
    if params.search_type == "doi" then
        local clean = normalize_doi(params.query)
        url = base_url .. "/DOI:" .. http.url_encode(clean) .. "?fields=" .. fields
    else
        url = base_url .. "/search?query=" .. http.url_encode(params.query)
            .. "&limit=" .. tostring(params.limit or 10)
            .. "&offset=" .. tostring(params.offset or 0)
            .. "&fields=" .. fields
    end

    log("Consultando Semantic Scholar: " .. url)
    local res = http.get(url, {
        headers = headers,
        timeout_secs = 12
    })

    if not res.ok then
        log("Semantic Scholar retornou status " .. tostring(res.status))
        return {}
    end

    local data = json.decode(res.body)
    if not data then return {} end

    local items = {}
    if params.search_type == "doi" then
        items = { data }
    else
        items = data.data or {}
    end

    local results = {}
    for _, paper in ipairs(items) do
        local doi = ""
        if paper.externalIds and paper.externalIds.DOI then
            doi = normalize_doi(paper.externalIds.DOI)
        end

        local pdf_url = nil
        if paper.openAccessPdf and paper.openAccessPdf.url and #paper.openAccessPdf.url > 0 then
            local u = paper.openAccessPdf.url
            if not u:find("https?://doi%.org") and not u:find("https?://dx%.doi%.org") then
                pdf_url = u
            end
        end

        table.insert(results, {
            doi = doi,
            title = paper.title,
            authors = extract_authors(paper.authors),
            journal = paper.venue,
            year = paper.year,
            abstract = paper.abstract,
            pdf_url = pdf_url,
            file_size = nil
        })
    end

    log("Semantic Scholar retornou " .. tostring(#results) .. " artigos")
    return results
end
