--[[
  NeoResearch Plugin: Excalidraw (Aba do Projeto)
  Target: project_tab
  Quadro branco Excalidraw por projeto, com salvamento automático da cena.
  A interface é renderizada pelo front-end (static/js/project_tabs.js,
  renderer "excalidraw"); a cena é guardada por projeto em
  /api/projects/{id}/documents/{tab_id}.
]]

plugin = {
    id = "excalidraw",
    name = "Excalidraw (Quadro Branco)",
    version = "1.0.0",
    author = "NeoResearch Oficial",
    description = "Aba de quadro branco Excalidraw em cada projeto, com salvamento automático.",
    target = "project_tab",
    default_enabled = true,
    ui = {
        type = "project_tab",
        renderer = "excalidraw",
        tab_id = "excalidraw",
        title = "Excalidraw",
        icon = "🎨",
        tooltip = "Quadro branco Excalidraw do projeto, salvo automaticamente"
    }
}
