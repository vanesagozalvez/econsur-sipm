options(shiny.error = function() {
  traceback(2)
  quit(status = 1)
})

cat("==== INICIO APP (DEBUG GLOBAL) ====\n")

tryCatch({

  # ── CARGA DE LIBRERÍAS ─────────────────────────────
  library(shiny)
  library(bs4Dash)
  library(dplyr)
  library(tidyr)
  library(highcharter)
  library(viridis)
  library(lubridate)
  library(shinycssloaders)
  library(waiter)

  cat("[OK] Librerías cargadas\n")

  # ── TEST BÁSICO (ANTES DE TU CÓDIGO REAL) ──────────
  cat("[TEST] Creando app mínima\n")

  ui <- fluidPage(
    h1("Test OK"),
    p("Si ves esto, el problema es tu código original")
  )

  server <- function(input, output, session) {
    cat("[OK] Server iniciado\n")
  }

  shinyApp(ui, server)

}, error = function(e) {

  cat("\n========= ERROR GLOBAL =========\n")
  cat(e$message, "\n")
  cat("================================\n")

  # FORZAR crash con mensaje
  stop(e)

})

