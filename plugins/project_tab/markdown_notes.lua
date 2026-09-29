--[[
  NeoResearch Plugin: Notas em Markdown (Aba do Projeto)
  Target: project_tab
  Um documento Markdown em branco por projeto, com pré-visualização e
  salvamento automático. A interface é renderizada pelo front-end
  (static/js/project_tabs.js, renderer "markdown"); o conteúdo é guardado
  por projeto em /api/projects/{id}/documents/{tab_id}.
]]

plugin = {
    id = "markdown_notes",
    name = "Notas em Markdown",
    version = "1.0.0",
    author = "NeoResearch Oficial",
    description = "Aba com um documento Markdown em branco por projeto, com pré-visualização e salvamento automático.",
    target = "project_tab",
    default_enabled = true,
    ui = {
        type = "project_tab",
        renderer = "markdown",
        tab_id = "markdown",
        title = "Notas (Markdown)",
        icon = "📝",
        tooltip = "Documento em Markdown do projeto, salvo automaticamente"
    }
}
