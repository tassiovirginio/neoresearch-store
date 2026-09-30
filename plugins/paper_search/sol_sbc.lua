-- Plugin SBC OpenLib (SOL) para NeoResearch
-- Biblioteca Digital da Sociedade Brasileira de Computação (SBC)
-- Repositório oficial de Anais de Congressos/Simpósios e Periódicos em Computação no Brasil
-- https://sol.sbc.org.br/

plugin = {
    id = "sol_sbc",
    name = "SBC OpenLib (SOL)",
    version = "1.0.1",
    author = "NeoResearch Community",
    description = "Busca de artigos, anais de eventos e periódicos da Sociedade Brasileira de Computação (SBC OpenLib / https://sol.sbc.org.br/)",
    target = "paper_search",
    default_enabled = true
}

local function clean_text(str)
    if not str then return nil end
    local s = str:gsub("%s+", " ")
    return s:match("^%s*(.-)%s*$")
end

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
        or year_from_date_parts(work.issued)
end

local function extract_pdf_url(work)
    if not work.link then return nil end
    for _, l in ipairs(work.link) do
        local content_type = l["content-type"] or ""
        local url = l.URL or ""
        if (content_type:find("pdf") or url:find("%.pdf")) and #url > 0 then
            if not url:find("https?://doi%.org") and not url:find("https?://dx%.doi%.org") then
                return url
            end
        end
    end
    return nil
end

local function search_sol_harvest(query, search_type, limit)
    local field_name = "query"
    if search_type == "title" then
        field_name = "field-3"
    elseif search_type == "author" then
        field_name = "field-4"
    elseif search_type == "keywords" or search_type == "subject" then
        field_name = "field-14"
    end

    local url = "https://sol.sbc.org.br/busca/index.php/integrada/results?" .. field_name .. "=" .. http.url_encode(query)
    log("Consultando busca direta SBC OpenLib (OHS): " .. url)

    local res = http.get(url, {
        headers = {
            ["User-Agent"] = "NeoResearch/1.0 (+https://sol.sbc.org.br; mailto:contato@neoresearch.science)"
        },
        timeout_secs = 10
    })

    if not res.ok or not res.body or #res.body == 0 then
        return {}
    end

    local results = {}
    local html = res.body

    for link, raw_title, contents in html:gmatch('<a%s+class="record_title"%s+href="([^"]+)"[^>]*>.-<span%s+class="title">(.-)</span>.-<div%s+class="recordContents">(.-)</div>') do
        if #results >= limit then
            break
        end

        local title = clean_text(raw_title:gsub("<.->", ""):gsub("&#039;", "'"):gsub("&quot;", '"'):gsub("&amp;", "&"))
        if title and #title > 0 then
            local authors = {}
            local raw_author = contents:match('<span%s+class="author">(.-)</span>')
            if raw_author then
                for author_name in raw_author:gmatch("([^;]+)") do
                    local a_clean = clean_text(author_name)
                    if a_clean and #a_clean > 0 then
                        table.insert(authors, a_clean)
                    end
                end
            end

            local journal = nil
            local raw_serie = contents:match('<div%s+class="archive_serie">(.-)</div>')
            if raw_serie then
                journal = clean_text(raw_serie:gsub("<.->", ""):gsub("&#039;", "'"):gsub("&quot;", '"'):gsub("&amp;", "&"))
            end

            local year = nil
            local raw_date = contents:match('<span%s+class="list_record_date">%s*([0-9]+)')
            if raw_date then
                year = tonumber(raw_date)
            end

            table.insert(results, {
                title = title,
                authors = authors,
                year = year,
                doi = "",
                journal = journal or "SBC OpenLib (SOL)",
                abstract = nil,
                pdf_url = nil,
                source = "SBC OpenLib",
                open_access = true
            })
        end
    end

    return results
end

function search(params)
    local query = params.query
    local limit = params.limit or 10
    local offset = params.offset or 0
    local search_type = params.search_type or "auto"

    -- Membro CrossRef 3742 = Sociedade Brasileira de Computação (SBC / SOL)
    -- Todos os artigos depositados pela SBC possuem prefixo 10.5753 e apontam para sol.sbc.org.br
    local base_url = "https://api.crossref.org/works"
    local contact_email = "contato@neoresearch.science"
    local url = ""

    if search_type == "doi" then
        local clean_doi = normalize_doi(query)
        if clean_doi:find("^10%.5753/") or clean_doi:find("5753") then
            url = base_url .. "/" .. http.url_encode(clean_doi) .. "?mailto=" .. contact_email
        else
            url = base_url .. "?query=" .. http.url_encode(clean_doi)
                .. "&filter=member:3742&rows=" .. tostring(limit)
                .. "&mailto=" .. contact_email
        end
    elseif search_type == "title" then
        url = base_url .. "?query.title=" .. http.url_encode(query)
            .. "&filter=member:3742"
            .. "&rows=" .. tostring(limit)
            .. "&offset=" .. tostring(offset)
            .. "&mailto=" .. contact_email
    elseif search_type == "author" then
        url = base_url .. "?query.author=" .. http.url_encode(query)
            .. "&filter=member:3742"
            .. "&rows=" .. tostring(limit)
            .. "&offset=" .. tostring(offset)
            .. "&mailto=" .. contact_email
    else
        url = base_url .. "?query=" .. http.url_encode(query)
            .. "&filter=member:3742"
            .. "&rows=" .. tostring(limit)
            .. "&offset=" .. tostring(offset)
            .. "&mailto=" .. contact_email
    end

    log("Consultando SBC OpenLib via CrossRef (Member 3742): " .. url)
    local res = http.get(url, {
        headers = {
            ["User-Agent"] = "NeoResearch/1.0 (+https://sol.sbc.org.br; mailto:contato@neoresearch.science)"
        },
        timeout_secs = 12
    })

    local results = {}

    if res.ok and res.body and #res.body > 0 then
        local data = json.decode(res.body)
        if data and data.message then
            local items = {}
            if data.message.items then
                items = data.message.items
            elseif data.message.title then
                items = { data.message }
            end

            for _, item in ipairs(items) do
                local raw_title = item.title and item.title[1]
                local title = clean_text(raw_title)

                if title and #title > 0 then
                    local authors = extract_authors(item.author)
                    local year = extract_year(item)
                    local doi = item.DOI or ""
                    local pdf_url = extract_pdf_url(item)

                    local journal = nil
                    if item["container-title"] and item["container-title"][1] and #item["container-title"][1] > 0 then
                        journal = clean_text(item["container-title"][1])
                    elseif item.event and item.event.name and #item.event.name > 0 then
                        journal = clean_text(item.event.name)
                    end

                    local abstract = nil
                    if item.abstract and #item.abstract > 0 then
                        abstract = clean_text(item.abstract:gsub("<.->", ""):gsub("&#039;", "'"):gsub("&quot;", '"'):gsub("&amp;", "&"))
                    end

                    table.insert(results, {
                        title = title,
                        authors = authors,
                        year = year,
                        doi = doi,
                        journal = journal or "SBC OpenLib (SOL)",
                        abstract = abstract,
                        pdf_url = pdf_url,
                        source = "SBC OpenLib",
                        open_access = true
                    })
                end
            end
        end
    else
        log("Consulta ao CrossRef Member 3742 falhou ou retornou vazio, status: " .. tostring(res.status))
    end

    -- Fallback para busca direta no portal SBC OpenLib se não houver resultados no CrossRef
    if #results == 0 and search_type ~= "doi" then
        log("Recorrendo à busca direta no portal SOL (sol.sbc.org.br)...")
        results = search_sol_harvest(query, search_type, limit)
    end

    log("SBC OpenLib retornou " .. tostring(#results) .. " artigos.")
    return results
end
