-- Plugin PubMed / NCBI para NeoResearch
-- Busca de literatura biomédica e ciências da vida da U.S. National Library of Medicine (NLM)

plugin = {
    id = "pubmed",
    name = "PubMed / NCBI",
    version = "1.0.0",
    author = "NeoResearch Community",
    description = "Busca de literatura médica e biomédica na National Library of Medicine (NLM / NIH)",
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

    -- 1. Buscar IDs no E-search
    local search_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term="
        .. http.url_encode(query)
        .. "&retmode=json&retmax=" .. tostring(limit)
        .. "&retstart=" .. tostring(offset)

    log("Consultando PubMed esearch: " .. search_url)
    local sres = http.get(search_url, {
        headers = {
            ["User-Agent"] = "NeoResearch/1.0 (+https://github.com/tassiovirginio/colabpesquisa)"
        },
        timeout_secs = 12
    })

    if not sres.ok then
        log("PubMed esearch retornou HTTP " .. tostring(sres.status))
        return {}
    end

    local sdata = json.decode(sres.body)
    if not sdata or not sdata.esearchresult or not sdata.esearchresult.idlist or #sdata.esearchresult.idlist == 0 then
        return {}
    end

    local id_list = sdata.esearchresult.idlist
    local id_str = table.concat(id_list, ",")

    -- 2. Buscar sumários dos IDs
    local summary_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id="
        .. id_str .. "&retmode=json"

    local sum_res = http.get(summary_url, {
        headers = {
            ["User-Agent"] = "NeoResearch/1.0 (+https://github.com/tassiovirginio/colabpesquisa)"
        },
        timeout_secs = 12
    })

    if not sum_res.ok then
        return {}
    end

    local sum_data = json.decode(sum_res.body)
    if not sum_data or not sum_data.result then
        return {}
    end

    local results = {}
    for _, uid in ipairs(id_list) do
        local doc = sum_data.result[uid]
        if doc and doc.title then
            local title = clean_text(doc.title)
            local authors = {}
            if doc.authors then
                for _, a in ipairs(doc.authors) do
                    if a.name then
                        table.insert(authors, a.name)
                    end
                end
            end

            local year = nil
            if doc.pubdate and #doc.pubdate >= 4 then
                year = tonumber(doc.pubdate:sub(1, 4))
            end

            local doi = nil
            if doc.articleids then
                for _, aid in ipairs(doc.articleids) do
                    if aid.idtype == "doi" then
                        doi = aid.value
                        break
                    end
                end
            end

            local pdf_url = nil
            if doi then
                pdf_url = "https://doi.org/" .. doi
            end

            table.insert(results, {
                title = title,
                authors = authors,
                year = year,
                doi = doi,
                pdf_url = nil,
                abstract = doc.source and ("Publicado em: " .. doc.source) or nil,
                source = "PubMed",
                open_access = false
            })
        end
    end

    return results
end
