# NeoResearch Store

Loja oficial de plugins do [NeoResearch](https://neoresearch.science). O app lê o `registry.json` deste
repositório e instala os scripts Lua de `plugins/` no grupo de pesquisa que pedir.

## Plugins

| Módulo | Plugins |
|---|---|
| `paper_search` | CrossRef, arXiv, OpenAlex, Europe PMC, Semantic Scholar, DBLP, PubMed, SciELO, SBC OpenLib, DOAJ, Zenodo, HAL, OpenAIRE, OpenReview, Unpaywall, CORE |
| `project_tab` | LaTeX (estilo Overleaf), Excalidraw, Notas em Markdown, Mermaid |
| `chat_bot` | Telegram, Discord, Chat interno |
| `whatsapp_bot` | WhatsApp |
| `media` | Rádio global e lofi |

Os plugins de busca usam só APIs abertas e oficiais. Não aceitamos plugins que baixem ou indexem material
pirateado (Sci-Hub e similares) nem que raspem páginas que proíbem isso nos termos de uso.

O CORE exige uma chave gratuita da API (`api_key` na configuração do plugin) e o Semantic Scholar aceita uma
chave opcional.

## Como funciona

- `registry.json`: catálogo (id, nome, versão, autor, descrição, tags, versão mínima do app e `download_url`).
- `plugins/<módulo>/<id>.lua`: o script do plugin. A primeira linha útil é o manifesto `plugin = { ... }`.

Os arquivos deste repositório são **gerados** a partir do código do NeoResearch
(`python3 scripts/build_store.py`); mude o plugin lá e republique aqui, em vez de editar direto.

## Repositórios próprios

Qualquer laboratório pode ter a sua loja: um repositório com um `registry.json` no mesmo formato, cadastrado
em Plugins → Repositórios.
