-- Plugin SciELO para NeoResearch
-- Scientific Electronic Library Online
-- Artigos científicos em acesso aberto da América Latina, Caribe, Espanha, Portugal e África do Sul

plugin = {
    id = "scielo",
    name = "SciELO Open Access",
    version = "1.0.0",
    author = "NeoResearch Community",
    description = "Biblioteca científica eletrônica online de periódicos da América Latina e Ibero-América",
    target = "paper_search",
    default_enabled = true
}

local function clean_text(str)
    if not str then return nil end
    local s = str:gsub("%s+", " ")
    return s:match("^%s*(.-)%s*$")
end

function search(params)
    local query = params.query
    local limit = params.limit or 10
    local offset = params.offset or 0

    -- SciELO no CrossRef (Membro 340)
    local url = "https://api.crossref.org/works?query=" .. http.url_encode(query)
        .. "&filter=member:340"
        .. "&rows=" .. tostring(limit)
        .. "&offset=" .. tostring(offset)

    log("Consultando SciELO (CrossRef Member 340): " .. url)
    local res = http.get(url, {
        headers = {
            ["User-Agent"] = "NeoResearch/1.0 (mailto:neoresearchglobal@gmail.com)"
        },
        timeout_secs = 12
    })

    if not res.ok then
        return {}
    end

    local data = json.decode(res.body)
    if not data or not data.message or not data.message.items then
        return {}
    end

    local results = {}
    for _, item in ipairs(data.message.items) do
        local raw_title = item.title and item.title[1]
        local title = clean_text(raw_title)

        if title and #title > 0 then
            local authors = {}
            if item.author then
                for _, a in ipairs(item.author) do
                    if a.given and a.family then
                        table.insert(authors, a.family .. ", " .. a.given)
                    elseif a.family then
                        table.insert(authors, a.family)
                    elseif a.name then
                        table.insert(authors, a.name)
                    end
                end
            end

            local year = nil
            if item.issued and item.issued["date-parts"] and item.issued["date-parts"][1] then
                year = tonumber(item.issued["date-parts"][1][1])
            end

            local doi = item.DOI
            local pdf_url = nil
            if item.link then
                for _, l in ipairs(item.link) do
                    if l["content-type"] and l["content-type"]:find("pdf") and l.URL then
                        pdf_url = l.URL
                        break
                    end
                end
            end

            table.insert(results, {
                title = title,
                authors = authors,
                year = year,
                doi = doi,
                pdf_url = pdf_url,
                abstract = item.abstract and clean_text(item.abstract:gsub("<.->", "")) or nil,
                source = "SciELO",
                open_access = true
            })
        end
    end

    return results
end
