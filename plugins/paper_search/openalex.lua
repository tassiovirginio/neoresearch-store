-- Plugin OpenAlex para NeoResearch
-- Uma das maiores bases bibliográficas abertas do mundo (sucessora do Microsoft Academic Graph)

plugin = {
    id = "openalex",
    name = "OpenAlex",
    version = "1.0.0",
    author = "NeoResearch",
    description = "Busca de literatura científica global com ampla cobertura e identificação de acesso aberto",
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

local function extract_authors(authorships)
    local authors = {}
    if not authorships then return authors end
    for _, a in ipairs(authorships) do
        if a.author and a.author.display_name and #a.author.display_name > 0 then
            table.insert(authors, a.author.display_name)
        elseif a.raw_author_name and #a.raw_author_name > 0 then
            table.insert(authors, a.raw_author_name)
        end
    end
    return authors
end

local function reconstruct_abstract(inverted_index)
    if not inverted_index then return nil end
    local word_positions = {}
    for word, positions in pairs(inverted_index) do
        for _, pos in ipairs(positions) do
            table.insert(word_positions, { pos = pos, word = word })
        end
    end
    table.sort(word_positions, function(a, b) return a.pos < b.pos end)
    local words = {}
    for _, wp in ipairs(word_positions) do
        table.insert(words, wp.word)
    end
    return table.concat(words, " ")
end

local function extract_pdf_url(work)
    if work.best_oa_location and work.best_oa_location.pdf_url and #work.best_oa_location.pdf_url > 0 then
        local url = work.best_oa_location.pdf_url
        if not url:find("https?://doi%.org") and not url:find("https?://dx%.doi%.org") then
            return url
        end
    end
    if work.primary_location and work.primary_location.pdf_url and #work.primary_location.pdf_url > 0 then
        local url = work.primary_location.pdf_url
        if not url:find("https?://doi%.org") and not url:find("https?://dx%.doi%.org") then
            return url
        end
    end
    return nil
end

function search(params)
    local base_url = "https://api.openalex.org/works"
    local contact_email = "neoresearchglobal@gmail.com"
    local url = ""

    if params.search_type == "doi" then
        local clean_doi = normalize_doi(params.query)
        url = base_url .. "/doi:" .. http.url_encode(clean_doi) .. "?mailto=" .. contact_email
    else
        local limit = params.limit or 10
        local offset = params.offset or 0
        local page = math.floor(offset / math.max(limit, 1)) + 1
        url = base_url .. "?search=" .. http.url_encode(params.query)
            .. "&per_page=" .. tostring(limit)
            .. "&page=" .. tostring(page)
            .. "&mailto=" .. contact_email
    end

    log("Consultando OpenAlex: " .. url)
    local res = http.get(url, {
        headers = {
            ["User-Agent"] = "NeoResearch/1.0 (+https://github.com/tassiovirginio/colabpesquisa)"
        },
        timeout_secs = 12
    })

    if not res.ok then
        log("OpenAlex retornou status " .. tostring(res.status))
        return {}
    end

    local data = json.decode(res.body)
    if not data then return {} end

    local items = {}
    if params.search_type == "doi" then
        items = { data }
    else
        items = data.results or {}
    end

    local results = {}
    for _, work in ipairs(items) do
        local raw_title = work.display_name or work.title
        local journal = nil
        if work.primary_location and work.primary_location.source and work.primary_location.source.display_name then
            journal = work.primary_location.source.display_name
        end

        local abstract = reconstruct_abstract(work.abstract_inverted_index)

        table.insert(results, {
            doi = normalize_doi(work.doi),
            title = raw_title,
            authors = extract_authors(work.authorships),
            journal = journal,
            year = work.publication_year,
            abstract = abstract,
            pdf_url = extract_pdf_url(work),
            file_size = nil
        })
    end

    log("OpenAlex retornou " .. tostring(#results) .. " artigos")
    return results
end
