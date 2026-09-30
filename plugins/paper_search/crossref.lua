-- Plugin CrossRef para NeoResearch
-- Fonte oficial de DOIs e metadados de milhares de editoras acadêmicas

plugin = {
    id = "crossref",
    name = "CrossRef",
    version = "1.0.1",
    author = "NeoResearch",
    description = "Busca de artigos científicos e DOIs na API pública do CrossRef",
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

local function extract_authors(work_authors)
    local authors = {}
    if not work_authors then return authors end
    for _, a in ipairs(work_authors) do
        if a.name and #a.name > 0 then
            table.insert(authors, a.name)
        elseif a.family then
            if a.given and #a.given > 0 then
                table.insert(authors, a.family .. ", " .. a.given)
            else
                table.insert(authors, a.family)
            end
        end
    end
    return authors
end

local function extract_year(work)
    local function year_from_date_parts(dp)
        if dp and dp["date-parts"] and dp["date-parts"][1] and dp["date-parts"][1][1] then
            return tonumber(dp["date-parts"][1][1])
        end
        return nil
    end

    return year_from_date_parts(work["published-print"])
        or year_from_date_parts(work["published-online"])
        or year_from_date_parts(work.published)
end

local function extract_pdf_url(work)
    if not work.link then return nil end
    for _, l in ipairs(work.link) do
        local content_type = l["content-type"] or ""
        local url = l.URL or ""
        if content_type:find("pdf") and #url > 0 then
            -- Ignora links que são meros redirecionamentos para doi.org
            if not url:find("https?://doi%.org") and not url:find("https?://dx%.doi%.org") then
                return url
            end
        end
    end
    return nil
end

function search(params)
    local base_url = "https://api.crossref.org/works"
    local contact_email = "contato@neoresearch.science"
    local url = ""

    if params.search_type == "doi" then
        local clean_doi = normalize_doi(params.query)
        url = base_url .. "/" .. http.url_encode(clean_doi) .. "?mailto=" .. contact_email
    else
        url = base_url .. "?query.bibliographic=" .. http.url_encode(params.query)
            .. "&rows=" .. tostring(params.limit or 10)
            .. "&offset=" .. tostring(params.offset or 0)
            .. "&mailto=" .. contact_email
    end

    log("Consultando CrossRef: " .. url)
    local res = http.get(url, {
        headers = {
            ["User-Agent"] = "NeoResearch/1.0 (+https://github.com/tassiovirginio/colabpesquisa; mailto:contato@neoresearch.science)"
        },
        timeout_secs = 12
    })

    if not res.ok then
        log("CrossRef retornou status " .. tostring(res.status))
        return {}
    end

    local data = json.decode(res.body)
    if not data or not data.message then
        return {}
    end

    local items = {}
    if params.search_type == "doi" then
        items = { data.message }
    else
        items = data.message.items or {}
    end

    local results = {}
    for _, item in ipairs(items) do
        local raw_title = nil
        if item.title and item.title[1] then
            raw_title = item.title[1]
        end

        local journal_name = nil
        if item["container-title"] and item["container-title"][1] then
            journal_name = item["container-title"][1]
        end

        table.insert(results, {
            doi = normalize_doi(item.DOI),
            title = raw_title,
            authors = extract_authors(item.author),
            journal = journal_name,
            year = extract_year(item),
            abstract = item["abstract"],
            pdf_url = extract_pdf_url(item),
            file_size = nil
        })
    end

    log("CrossRef retornou " .. tostring(#results) .. " artigos")
    return results
end
