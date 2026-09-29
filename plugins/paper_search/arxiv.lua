-- Plugin arXiv para NeoResearch
-- Preprints de Ciência da Computação, Física, Matemática e áreas afins

plugin = {
    id = "arxiv",
    name = "arXiv",
    version = "1.0.0",
    author = "NeoResearch",
    description = "Busca de preprints em computação, física e matemática no repositório arXiv.org",
    target = "paper_search",
    default_enabled = true
}

local function clean_text(str)
    if not str then return nil end
    local s = str:gsub("%s+", " ")
    return s:match("^%s*(.-)%s*$")
end

function search(params)
    if params.search_type == "doi" then
        return {}
    end

    local field = "all"
    if params.search_type == "title" then
        field = "ti"
    elseif params.search_type == "author" then
        field = "au"
    elseif params.search_type == "keywords" then
        field = "abs"
    end

    local search_query = field .. ":" .. params.query
    local base_url = "https://export.arxiv.org/api/query"
    local url = base_url .. "?search_query=" .. http.url_encode(search_query)
        .. "&start=" .. tostring(params.offset or 0)
        .. "&max_results=" .. tostring(params.limit or 10)

    log("Consultando arXiv: " .. url)
    local res = http.get(url, {
        headers = {
            ["User-Agent"] = "NeoResearch/1.0 (+https://github.com/tassiovirginio/colabpesquisa)"
        },
        timeout_secs = 12
    })

    if not res.ok then
        log("arXiv retornou status " .. tostring(res.status))
        return {}
    end

    local entries = xml.extract_tags(res.body, "entry")
    local results = {}

    for _, entry in ipairs(entries) do
        local id_url = xml.extract_tag(entry, "id") or ""
        local raw_title = xml.extract_tag(entry, "title")
        local title = clean_text(raw_title)
        local raw_summary = xml.extract_tag(entry, "summary")
        local summary = clean_text(raw_summary)
        local published = xml.extract_tag(entry, "published") or ""
        local journal = xml.extract_tag(entry, "arxiv:journal_ref")
        local raw_doi = xml.extract_tag(entry, "arxiv:doi")

        local arxiv_id = id_url:match("([^/]+)$") or ""
        local doi = ""
        if raw_doi and #raw_doi > 0 then
            doi = raw_doi
        elseif #arxiv_id > 0 then
            doi = "arXiv:" .. arxiv_id
        end

        local pdf_url = nil
        -- Procura por link com title="pdf"
        local pdf_match = entry:match('<link[^>]-title="pdf"[^>]-href="([^"]+)"')
        if pdf_match then
            pdf_url = pdf_match
        elseif #arxiv_id > 0 then
            pdf_url = "https://arxiv.org/pdf/" .. arxiv_id
        end

        local year = nil
        local year_match = published:match("^(%d%d%d%d)")
        if year_match then
            year = tonumber(year_match)
        end

        local authors = {}
        local author_tags = xml.extract_tags(entry, "author")
        for _, atag in ipairs(author_tags) do
            local name = xml.extract_tag(atag, "name")
            if name and #name > 0 then
                table.insert(authors, clean_text(name))
            end
        end

        table.insert(results, {
            doi = doi,
            title = title,
            authors = authors,
            journal = journal or "arXiv preprint",
            year = year,
            abstract = summary,
            pdf_url = pdf_url,
            file_size = nil
        })
    end

    log("arXiv retornou " .. tostring(#results) .. " preprints")
    return results
end
