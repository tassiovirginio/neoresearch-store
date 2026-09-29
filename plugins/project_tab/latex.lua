--[[
  NeoResearch Plugin: LaTeX (Aba do Projeto) — ambiente parecido com o Overleaf
  Target: project_tab

  Editor LaTeX com destaque de sintaxe, várias páginas/arquivos (.tex, .bib, .sty,
  imagens), botão de compilar, pré-visualização do PDF, registro do TeX e lista de
  erros clicável, com salvamento automático por projeto.

  REQUISITO NO SERVIDOR: o TinyTeX precisa estar instalado no servidor onde o
  NeoResearch roda (a compilação é feita lá). Instale com:
      bash scripts/install_tinytex.sh
  Enquanto o TinyTeX não estiver instalado, a aba abre e permite editar, mas o botão
  "Compilar" fica desativado e a própria aba mostra como instalar.

  A interface é renderizada pelo front-end (static/js/latex_tab.js, renderer "latex");
  os arquivos ficam em /api/projects/{id}/documents/{tab_id} e a compilação em
  /api/projects/{id}/latex/compile (sem shell-escape, com limites de tempo/memória).
]]

plugin = {
    id = "latex",
    name = "LaTeX (estilo Overleaf)",
    version = "1.0.0",
    author = "NeoResearch Oficial",
    description = "Editor LaTeX por projeto com compilação para PDF, pré-visualização, registro e erros clicáveis. Requer o TinyTeX instalado no servidor (scripts/install_tinytex.sh).",
    target = "project_tab",
    default_enabled = true,
    ui = {
        type = "project_tab",
        renderer = "latex",
        tab_id = "latex",
        title = "LaTeX",
        icon = "📄",
        tooltip = "Editor LaTeX do projeto com compilação para PDF (requer TinyTeX no servidor)",
        requires = "TinyTeX instalado no servidor"
    }
}
