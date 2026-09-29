-- Plugin DBLP para NeoResearch
-- DBLP Computer Science Bibliography
-- Busca de artigos, conferências e periódicos em Ciência da Computação

plugin = {
    id = "dblp",
    name = "DBLP Computer Science",
    version = "1.0.0",
    author = "NeoResearch Community",
    description = "Índice de literatura científica em Ciência da Computação da DBLP Trier",
    target = "paper_search",
    default_enabled = true
}

local function clean_text(str)
    if not str then return nil end
    local s = str:gsub("%s+", " ")
    s = s:gsub("%.$", "")
    return s:match("^%s*(.-)%s*$")
end

function search(params)
    if params.search_type == "doi" then
        return {}
    end

    local query = params.query
    local limit = params.limit or 10
    local offset = params.offset or 0

    local url = "https://dblp.org/search/publ/api?q=" .. http.url_encode(query)
        .. "&format=json&h=" .. tostring(limit)
        .. "&f=" .. tostring(offset)

    log("Consultando DBLP: " .. url)
    local res = http.get(url, {
        headers = {
            ["User-Agent"] = "NeoResearch/1.0 (+https://github.com/tassiovirginio/colabpesquisa)"
        },
        timeout_secs = 12
    })

    if not res.ok then
        log("DBLP retornou status HTTP " .. tostring(res.status))
        return {}
    end

    local data = json.decode(res.body)
    if not data or not data.result or not data.result.hits or not data.result.hits.hit then
        return {}
    end

    local hits = data.result.hits.hit
    if hits.info then
        hits = { hits }
    end

    local results = {}
    for _, hit in ipairs(hits) do
        local info = hit.info or {}
        local raw_title = info.title
        local title = clean_text(raw_title)

        if title and #title > 0 then
            local authors = {}
            if info.authors and info.authors.author then
                local raw_authors = info.authors.author
                if type(raw_authors) == "table" and raw_authors.text then
                    table.insert(authors, raw_authors.text)
                elseif type(raw_authors) == "table" then
                    for _, a in ipairs(raw_authors) do
                        if type(a) == "table" and a.text then
                            table.insert(authors, a.text)
                        elseif type(a) == "string" then
                            table.insert(authors, a)
                        end
                    end
                elseif type(raw_authors) == "string" then
                    table.insert(authors, raw_authors)
                end
            end

            local year = tonumber(info.year)
            local doi = info.doi
            local url_link = info.ee or info.url

            local pdf_url = nil
            if url_link and url_link:find("%.pdf") then
                pdf_url = url_link
            end

            table.insert(results, {
                title = title,
                authors = authors,
                year = year,
                doi = doi,
                pdf_url = pdf_url,
                abstract = info.venue and ("Publicado em: " .. info.venue) or nil,
                source = "DBLP",
                open_access = pdf_url ~= nil
            })
        end
    end

    return results
end
