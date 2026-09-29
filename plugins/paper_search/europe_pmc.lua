-- Plugin Europe PMC para NeoResearch
-- Repositório biomédico e científico internacional mantido pelo EMBL-EBI

plugin = {
    id = "europe_pmc",
    name = "Europe PMC",
    version = "1.0.0",
    author = "NeoResearch",
    description = "Busca de artigos de biologia, medicina e ciências biomédicas com links diretos de acesso aberto",
    target = "paper_search",
    default_enabled = true
}

local function normalize_doi(doi)
    if not doi then return "" end
    local clean = doi:gsub("^https?://doi%.org/", "")
    clean = clean:gsub("^doi%.org/", "")
    clean = clean:gsub("^[Dd][Oo][Ii]:", "")
    return clean:match("^%s*(.-)%s*$")
end

local function parse_authors(author_string)
    local authors = {}
    if not author_string then return authors end
    for a in author_string:gmatch("([^,]+)") do
        local trimmed = a:match("^%s*(.-)%s*$")
        if #trimmed > 0 then
            table.insert(authors, trimmed)
        end
    end
    return authors
end

local function extract_pdf_url(work)
    if not work.fullTextUrlList or not work.fullTextUrlList.fullTextUrl then
        return nil
    end

    local candidate = nil
    for _, item in ipairs(work.fullTextUrlList.fullTextUrl) do
        local style = (item.documentStyle or ""):lower()
        local url = item.url or ""
        local is_oa = (item.availability == "Open access" or item.availabilityCode == "OA")

        if style == "pdf" and #url > 0 then
            if not url:find("https?://doi%.org") and not url:find("https?://dx%.doi%.org") then
                if is_oa then
                    return url
                end
                if not candidate then
                    candidate = url
                end
            end
        end
    end
    return candidate
end

function search(params)
    local base_url = "https://www.ebi.ac.uk/europepmc/webservices/rest/search"
    local query_string = params.query

    if params.search_type == "doi" then
        local clean = normalize_doi(params.query)
        query_string = 'DOI:"' .. clean .. '"'
    end

    local limit = params.limit or 10
    local offset = params.offset or 0
    local page_size = math.min(limit + offset, 100)

    local url = base_url .. "?query=" .. http.url_encode(query_string)
        .. "&format=json&resultType=core"
        .. "&pageSize=" .. tostring(page_size)

    log("Consultando Europe PMC: " .. url)
    local res = http.get(url, {
        headers = {
            ["User-Agent"] = "NeoResearch/1.0 (+https://github.com/tassiovirginio/colabpesquisa)"
        },
        timeout_secs = 12
    })

    if not res.ok then
        log("Europe PMC retornou status " .. tostring(res.status))
        return {}
    end

    local data = json.decode(res.body)
    if not data or not data.resultList or not data.resultList.result then
        return {}
    end

    local all_items = data.resultList.result
    local results = {}

    for i = (offset + 1), math.min(#all_items, offset + limit) do
        local work = all_items[i]
        if work then
            local journal_title = nil
            if work.journalInfo and work.journalInfo.journal and work.journalInfo.journal.title then
                journal_title = work.journalInfo.journal.title
            end

            local year = nil
            if work.pubYear then
                year = tonumber(work.pubYear)
            end

            table.insert(results, {
                doi = normalize_doi(work.doi),
                title = work.title,
                authors = parse_authors(work.authorString),
                journal = journal_title,
                year = year,
                abstract = work.abstractText,
                pdf_url = extract_pdf_url(work),
                file_size = nil
            })
        end
    end

    log("Europe PMC retornou " .. tostring(#results) .. " artigos")
    return results
end
