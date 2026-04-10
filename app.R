library(shiny)

cat("APP MINIMA INICIADA\n")

ui <- fluidPage(
  h1("App funcionando"),
  p("Si ves esto, el problema NO es Docker")
)

server <- function(input, output, session) {
  cat("SERVER OK\n")
}

shinyApp(ui, server)
