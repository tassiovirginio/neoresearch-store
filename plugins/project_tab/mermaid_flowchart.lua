--[[
  NeoResearch Plugin: Mermaid Flowchart (Aba do Projeto)
  Target: project_tab
  Editor de diagramas Mermaid (fluxogramas, sequência, classes, estados, ER,
  Gantt, pizza...) com pré-visualização ao vivo, no estilo de
  https://www.mermaidonline.live/flowchart, e salvamento automático por projeto.
  A interface é renderizada pelo front-end (static/js/project_tabs.js,
  renderer "mermaid"); o código é guardado em /api/projects/{id}/documents/{tab_id}.
]]

plugin = {
    id = "mermaid_flowchart",
    name = "Mermaid Flowchart",
    version = "1.0.0",
    author = "NeoResearch Oficial",
    description = "Aba com editor de diagramas Mermaid (fluxogramas, sequência, classes e mais) com pré-visualização ao vivo e salvamento automático.",
    target = "project_tab",
    default_enabled = true,
    ui = {
        type = "project_tab",
        renderer = "mermaid",
        tab_id = "mermaid",
        title = "Fluxograma (Mermaid)",
        icon = "🔀",
        tooltip = "Editor de diagramas Mermaid do projeto, salvo automaticamente"
    }
}
