library(shiny)

cat("==== APP INICIANDO ====\n")

# ── UI ─────────────────────────────────────────────
ui <- fluidPage(
  h1("App funcionando"),
  p("Si ves esto, la base funciona")
)

# ── SERVER ─────────────────────────────────────────
server <- function(input, output, session) {
  cat("SERVER OK\n")
}

# ── RUN APP (ESTO ES OBLIGATORIO) ─────────────────
shinyApp(ui = ui, server = server)
