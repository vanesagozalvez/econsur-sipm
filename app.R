library(shiny)
library(bs4Dash)
library(dplyr)
library(tidyr)
library(tibble)
library(highcharter)
library(viridis)
library(lubridate)
library(shinycssloaders)
library(waiter)

cat("[STARTUP] Packages loaded\n")
cat("[STARTUP] Working dir:", getwd(), "\n")
cat("[STARTUP] IPIM exists:", file.exists("data/indice_ipim.csv"), "\n")
cat("[STARTUP] IPIB exists:", file.exists("data/indice_ipib.csv"), "\n")
cat("[STARTUP] IPP  exists:", file.exists("data/indice_ipp.csv"),  "\n")

# ── Helpers ──────────────────────────────────────────────────────────────────
traducir_mes <- function(mes_ingles) {
  meses    <- c("january","february","march","april","may","june",
                "july","august","september","october","november","december")
  meses_es <- c("Enero","Febrero","Marzo","Abril","Mayo","Junio",
                "Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre")
  idx <- match(tolower(mes_ingles), meses)
  if (!is.na(idx)) meses_es[idx] else mes_ingles
}

interanual_rolling_from_vm <- function(vm_vec) {
  n      <- length(vm_vec)
  result <- rep(NA_real_, n)
  fac    <- vm_vec / 100 + 1
  for (i in 12:n) {
    w <- fac[(i - 11):i]
    if (!any(is.na(w))) result[i] <- round((prod(w) - 1) * 100, 2)
  }
  result
}

load_index <- function(path, col_name) {
  cat("[LOAD]", path, "\n")
  raw <- read.csv2(path, encoding = "latin1",
                   stringsAsFactors = FALSE, na.strings = c("NA", ""))
  cat("[LOAD] cols:", paste(colnames(raw), collapse=", "), "\n")
  raw[[col_name]] <- suppressWarnings(as.numeric(gsub(",", ".", raw[[col_name]])))
  raw$periodo     <- as.Date(raw$periodo)
  raw %>%
    filter(!is.na(periodo), !is.na(.data[[col_name]])) %>%
    arrange(nivel_general_aperturas, periodo) %>%
    group_by(nivel_general_aperturas) %>%
    mutate(
      indice = .data[[col_name]],
      v_m    = round((indice / lag(indice) - 1) * 100, 2),
      v_ia   = interanual_rolling_from_vm(v_m)
    ) %>%
    ungroup()
}

# ── Carga de datos ────────────────────────────────────────────────────────────
ipim_raw <- load_index("data/indice_ipim.csv", "indice_ipim")
ipib_raw <- load_index("data/indice_ipib.csv", "indice_ipib")
ipp_raw  <- load_index("data/indice_ipp.csv",  "indice_ipp")

cat("[STARTUP] Rows IPIM:", nrow(ipim_raw), "\n")
cat("[STARTUP] Rows IPIB:", nrow(ipib_raw), "\n")
cat("[STARTUP] Rows IPP: ", nrow(ipp_raw),  "\n")

ultimo_periodo <- max(ipim_raw$periodo, na.rm = TRUE)
ultimo_label   <- paste0(traducir_mes(format(ultimo_periodo, "%B")),
                         " de ", format(ultimo_periodo, "%Y"))

cat("[STARTUP] Ultimo periodo:", as.character(ultimo_periodo), "\n")

# ── Constantes ────────────────────────────────────────────────────────────────
TOP_IPIM <- c("ng_nivel_general", "1_primarios",
              "2_industria_manufacturera_ y_energia_electrica",
              "i_productos_importados")
TOP_IPIB <- c("ng_nivel_general", "1_primarios",
              "2_industria_manufacturera_ y_energia_electrica",
              "i_productos_importados")
TOP_IPP  <- c("ng_nivel_general", "1_primarios",
              "2_industria_manufacturera_ y_energia_electrica")

LABEL_MAP <- c(
  "ng_nivel_general"                               = "Nivel General",
  "1_primarios"                                    = "Primarios",
  "2_industria_manufacturera_ y_energia_electrica" = "Ind. Manuf. y Energia",
  "i_productos_importados"                         = "Importados"
)

COLORES_COMP <- c(
  "Nivel General"         = "#37474f",
  "Primarios"             = "#1565c0",
  "Ind. Manuf. y Energia" = "#c62828",
  "Importados"            = "#2e7d32"
)

COLORES_IDX <- c("IPIM" = "#1565c0", "IPIB" = "#c62828", "IPP" = "#2e7d32")

last_val <- function(df, code, var = "v_m") {
  df %>%
    filter(nivel_general_aperturas == code, !is.na(.data[[var]])) %>%
    arrange(periodo) %>% tail(1) %>% pull(var)
}

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- dashboardPage(
  options   = FALSE,
  preloader = list(html = tagList(spin_6(), " Cargando..."), color = "#1a237e"),
  header    = dashboardHeader(
    skin  = "dark", fixed = TRUE,
    title = dashboardBrand(
      title = "EconSur - SIPM Argentina",
      image = "https://upload.wikimedia.org/wikipedia/commons/6/64/Logo_Indec.png"
    )
  ),
  sidebar = dashboardSidebar(skin = "light", width = 280,
    sidebarMenu(
      menuItem("Principal - SIPM", tabName = "principal", icon = icon("home")),
      menuItem("IPIM",             tabName = "ipim",      icon = icon("industry")),
      menuItem("IPIB",             tabName = "ipib",      icon = icon("boxes-stacked")),
      menuItem("IPP",              tabName = "ipp",       icon = icon("tractor")),
      menuItem("Acerca de",        tabName = "about",     icon = icon("info-circle"))
    )
  ),
  body = dashboardBody(
    tags$head(tags$style(HTML("
      .small-box .inner { text-align:center!important; font-size:30px!important; }
      h3 { color:#1a237e; }
      .card-title { font-weight:600; }
    "))),
    tabItems(

      # ── Tab 1: Principal ─────────────────────────────────────────────────
      tabItem(tabName = "principal",
        h3("Sistema de Indices de Precios Mayoristas (SIPM)"),
        p(paste0("Serie actualizada a ", ultimo_label, ". Fuente: INDEC. Base: dic-2015=100.")),
        fluidRow(
          bs4ValueBoxOutput("vb_ipim", width = 4),
          bs4ValueBoxOutput("vb_ipib", width = 4),
          bs4ValueBoxOutput("vb_ipp",  width = 4)
        ),
        fluidRow(
          bs4Card(width = 12, title = "Evolucion Comparada de los Indices", status = "primary",
            fluidRow(
              column(6,
                radioButtons("rng_principal", "Periodo:",
                  choices  = c("Historico", "Ultimos 36 meses", "Ultimos 12 meses"),
                  selected = "Historico", inline = TRUE)
              ),
              column(6,
                radioButtons("metrica_principal", "Metrica:",
                  choices  = c("Nivel (base 100)", "Variacion Mensual %", "Variacion Interanual %"),
                  selected = "Nivel (base 100)", inline = TRUE)
              )
            ),
            withSpinner(highchartOutput("plot_principal_lineas", height = "400px"), type = 4)
          )
        ),
        fluidRow(
          column(6,
            bs4Card(width = 12,
              title  = paste0("Variacion Mensual - ", ultimo_label),
              status = "info",
              withSpinner(highchartOutput("plot_principal_barras_m",  height = "260px"), type = 4)
            )
          ),
          column(6,
            bs4Card(width = 12,
              title  = paste0("Variacion Interanual - ", ultimo_label),
              status = "warning",
              withSpinner(highchartOutput("plot_principal_barras_ia", height = "260px"), type = 4)
            )
          )
        )
      ),

      # ── Tab 2: IPIM ──────────────────────────────────────────────────────
      tabItem(tabName = "ipim",
        h3("IPIM - Indice de Precios Internos al por Mayor"),
        p(paste0("Componentes vs Nivel General. Datos a ", ultimo_label, ".")),
        bs4Card(width = 12, title = "Evolucion de Componentes", status = "primary",
          fluidRow(
            column(6,
              radioButtons("rng_ipim", "Periodo:",
                choices  = c("Historico", "Ultimos 36 meses", "Ultimos 12 meses"),
                selected = "Historico", inline = TRUE)
            ),
            column(6,
              radioButtons("metrica_ipim", "Metrica:",
                choices  = c("Nivel (base 100)", "Variacion Mensual %", "Variacion Interanual %"),
                selected = "Nivel (base 100)", inline = TRUE)
            )
          ),
          withSpinner(highchartOutput("plot_ipim_lineas", height = "420px"), type = 4)
        ),
        fluidRow(
          column(6,
            bs4Card(width = 12,
              title  = paste0("Variacion Mensual por Componente - ", ultimo_label),
              status = "info",
              withSpinner(highchartOutput("plot_ipim_barras_m",  height = "280px"), type = 4)
            )
          ),
          column(6,
            bs4Card(width = 12,
              title  = paste0("Variacion Interanual por Componente - ", ultimo_label),
              status = "warning",
              withSpinner(highchartOutput("plot_ipim_barras_ia", height = "280px"), type = 4)
            )
          )
        )
      ),

      # ── Tab 3: IPIB ──────────────────────────────────────────────────────
      tabItem(tabName = "ipib",
        h3("IPIB - Indice de Precios Internos Basicos al por Mayor"),
        p(paste0("Componentes vs Nivel General. Datos a ", ultimo_label, ".")),
        bs4Card(width = 12, title = "Evolucion de Componentes", status = "primary",
          fluidRow(
            column(6,
              radioButtons("rng_ipib", "Periodo:",
                choices  = c("Historico", "Ultimos 36 meses", "Ultimos 12 meses"),
                selected = "Historico", inline = TRUE)
            ),
            column(6,
              radioButtons("metrica_ipib", "Metrica:",
                choices  = c("Nivel (base 100)", "Variacion Mensual %", "Variacion Interanual %"),
                selected = "Nivel (base 100)", inline = TRUE)
            )
          ),
          withSpinner(highchartOutput("plot_ipib_lineas", height = "420px"), type = 4)
        ),
        fluidRow(
          column(6,
            bs4Card(width = 12,
              title  = paste0("Variacion Mensual por Componente - ", ultimo_label),
              status = "info",
              withSpinner(highchartOutput("plot_ipib_barras_m",  height = "280px"), type = 4)
            )
          ),
          column(6,
            bs4Card(width = 12,
              title  = paste0("Variacion Interanual por Componente - ", ultimo_label),
              status = "warning",
              withSpinner(highchartOutput("plot_ipib_barras_ia", height = "280px"), type = 4)
            )
          )
        )
      ),

      # ── Tab 4: IPP ───────────────────────────────────────────────────────
      tabItem(tabName = "ipp",
        h3("IPP - Indice de Precios Basicos del Productor"),
        p(paste0("Componentes vs Nivel General. Datos a ", ultimo_label, ".")),
        bs4Card(width = 12, title = "Evolucion de Componentes", status = "primary",
          fluidRow(
            column(6,
              radioButtons("rng_ipp", "Periodo:",
                choices  = c("Historico", "Ultimos 36 meses", "Ultimos 12 meses"),
                selected = "Historico", inline = TRUE)
            ),
            column(6,
              radioButtons("metrica_ipp", "Metrica:",
                choices  = c("Nivel (base 100)", "Variacion Mensual %", "Variacion Interanual %"),
                selected = "Nivel (base 100)", inline = TRUE)
            )
          ),
          withSpinner(highchartOutput("plot_ipp_lineas", height = "420px"), type = 4)
        ),
        fluidRow(
          column(6,
            bs4Card(width = 12,
              title  = paste0("Variacion Mensual por Componente - ", ultimo_label),
              status = "info",
              withSpinner(highchartOutput("plot_ipp_barras_m",  height = "280px"), type = 4)
            )
          ),
          column(6,
            bs4Card(width = 12,
              title  = paste0("Variacion Interanual por Componente - ", ultimo_label),
              status = "warning",
              withSpinner(highchartOutput("plot_ipp_barras_ia", height = "280px"), type = 4)
            )
          )
        )
      ),

      # ── Acerca de ────────────────────────────────────────────────────────
      tabItem(tabName = "about",
        h2("Acerca de EconSur - SIPM"),
        bs4Card(width = 8,
          title       = strong("Sistema de Indices de Precios Mayoristas"),
          solidHeader = TRUE, status = "primary",
          p("Dashboard del SIPM publicado por INDEC. Base: diciembre 2015 = 100."),
          p("El ultimo mes publicado es dato provisorio."),
          tags$ul(
            tags$li(strong("IPIM:"), " Indice de Precios Internos al por Mayor"),
            tags$li(strong("IPIB:"), " Indice de Precios Internos Basicos al por Mayor"),
            tags$li(strong("IPP:"),  " Indice de Precios Basicos del Productor")
          ),
          tags$hr(),
          p(strong("Componentes:"),
            tags$ul(
              tags$li(strong("Nivel General:"), " agregado total del indice"),
              tags$li(strong("Primarios:"), " productos agropecuarios y mineros sin transformar"),
              tags$li(strong("Ind. Manuf. y Energia:"), " manufacturas y energia electrica"),
              tags$li(strong("Importados:"), " bienes importados (IPIM e IPIB)")
            )
          ),
          tags$hr(),
          p("Fuente: ", tags$a(href = "https://www.indec.gob.ar/", "INDEC"),
            " - Direccion Nacional de Estadisticas de Precios."),
          p("Deploy: ", tags$a(href = "https://render.com/", "Render (Docker)"))
        )
      )
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  hc_sipm_theme <- function(hc) {
    hc %>%
      hc_credits(
        enabled = TRUE, text = "INDEC", href = "https://www.indec.gob.ar/",
        align = "right", verticalAlign = "bottom",
        style = list(fontSize = "10px", color = "#555")
      ) %>%
      hc_tooltip(crosshairs = TRUE, backgroundColor = "#F0F0F0",
                 shared = TRUE, borderWidth = 2)
  }

  metrica_col <- function(metrica) {
    switch(metrica,
      "Nivel (base 100)"       = "indice",
      "Variacion Mensual %"    = "v_m",
      "Variacion Interanual %"  = "v_ia"
    )
  }

  metrica_ytitle <- function(metrica) {
    switch(metrica,
      "Nivel (base 100)"       = "Indice (dic-2015=100)",
      "Variacion Mensual %"    = "% Mensual",
      "Variacion Interanual %"  = "% Interanual"
    )
  }

  filtrar_rng <- function(df, rng) {
    max_p <- max(df$periodo, na.rm = TRUE)
    if (rng == "Ultimos 36 meses") df <- df %>% filter(periodo >= max_p %m-% months(36))
    if (rng == "Ultimos 12 meses") df <- df %>% filter(periodo >= max_p %m-% months(12))
    df
  }

  build_lineas <- function(df, codes, metrica, rng, titulo) {
    col_val <- metrica_col(metrica)
    ytitle  <- metrica_ytitle(metrica)

    df_top <- df %>%
      filter(nivel_general_aperturas %in% codes, !is.na(.data[[col_val]])) %>%
      mutate(label = LABEL_MAP[nivel_general_aperturas],
             val   = .data[[col_val]]) %>%
      filtrar_rng(rng)

    orden  <- c("Nivel General", "Primarios", "Ind. Manuf. y Energia", "Importados")
    labels <- intersect(orden, unique(df_top$label))

    hc <- highchart() %>%
      hc_chart(type = "line") %>%
      hc_xAxis(type = "datetime",
               dateTimeLabelFormats = list(month = "%b %Y"),
               labels = list(style = list(color = "black", fontWeight = "bold"))) %>%
      hc_yAxis(title = list(text = ytitle,
                            style = list(color = "black", fontWeight = "bold")),
               gridLineWidth = 1,
               labels = list(style = list(color = "black"))) %>%
      hc_legend(enabled = TRUE,
                itemStyle = list(fontWeight = "bold", fontSize = "12px")) %>%
      hc_title(text  = paste0(titulo, " - ", metrica),
               style = list(fontSize = "15px", fontWeight = "bold")) %>%
      hc_subtitle(text  = ultimo_label,
                  style = list(fontSize = "11px", color = "#555")) %>%
      hc_tooltip(shared = TRUE,
                 pointFormat = paste0(
                   "<span style='color:{series.color}'>&#9679;</span> ",
                   "{series.name}: <b>{point.y:.2f}</b><br/>")) %>%
      hc_sipm_theme()

    for (lbl in labels) {
      sdata <- df_top %>% filter(label == lbl) %>% arrange(periodo)
      col_s <- COLORES_COMP[lbl]
      if (is.na(col_s)) col_s <- "#607d8b"
      hc <- hc %>% hc_add_series(
        data      = sdata,
        type      = "line",
        hcaes(x   = periodo, y = val),
        name      = lbl,
        color     = col_s,
        lineWidth = if (lbl == "Nivel General") 3 else 2,
        dashStyle = if (lbl == "Nivel General") "ShortDash" else "Solid",
        marker    = list(enabled = FALSE)
      )
    }
    hc
  }

  build_barras <- function(df, codes, varname, ytitle, titulo) {
    bd <- df %>%
      filter(nivel_general_aperturas %in% codes, !is.na(.data[[varname]])) %>%
      group_by(nivel_general_aperturas) %>%
      slice_max(periodo, n = 1) %>% ungroup() %>%
      mutate(
        label = LABEL_MAP[nivel_general_aperturas],
        val   = round(.data[[varname]], 2),
        color = COLORES_COMP[label]
      ) %>%
      arrange(val) %>%
      mutate(label = factor(label, levels = label))

    hchart(bd, "bar", hcaes(x = label, y = val, color = color),
           showInLegend = FALSE,
           dataLabels = list(
             enabled = TRUE, format = "{point.y:.1f} %",
             style   = list(fontSize = "11px", fontWeight = "bold",
                            textOutline = "none", color = "black")
           )
    ) %>%
      hc_title(text  = titulo,
               style = list(fontSize = "13px", fontWeight = "bold")) %>%
      hc_subtitle(text  = ultimo_label,
                  style = list(fontSize = "11px", color = "#555")) %>%
      hc_xAxis(labels = list(
        style = list(color = "black", fontWeight = "bold", fontSize = "12px"))) %>%
      hc_yAxis(title = list(text = ytitle,
                            style = list(color = "black", fontWeight = "bold")),
               gridLineWidth = 1,
               labels = list(style = list(color = "black"))) %>%
      hc_tooltip(pointFormat = "<b>{point.y:.2f} %</b>") %>%
      hc_sipm_theme() %>%
      hc_legend(enabled = FALSE) %>%
      hc_plotOptions(bar = list(borderRadius = 3,
                                groupPadding = 0.05, pointPadding = 0.05))
  }

  # ── KPIs ─────────────────────────────────────────────────────────────────
  output$vb_ipim <- renderbs4ValueBox({
    vm  <- round(last_val(ipim_raw, "ng_nivel_general", "v_m"),  1)
    via <- round(last_val(ipim_raw, "ng_nivel_general", "v_ia"), 1)
    bs4ValueBox(
      value    = paste0(vm, " %"),
      subtitle = paste0("IPIM - Mensual | Interanual: ", via, " %"),
      icon     = icon("arrow-up"), color = "primary",
      footer   = div(ultimo_label)
    )
  })

  output$vb_ipib <- renderbs4ValueBox({
    vm  <- round(last_val(ipib_raw, "ng_nivel_general", "v_m"),  1)
    via <- round(last_val(ipib_raw, "ng_nivel_general", "v_ia"), 1)
    bs4ValueBox(
      value    = paste0(vm, " %"),
      subtitle = paste0("IPIB - Mensual | Interanual: ", via, " %"),
      icon     = icon("arrow-up"), color = "danger",
      footer   = div(ultimo_label)
    )
  })

  output$vb_ipp <- renderbs4ValueBox({
    vm  <- round(last_val(ipp_raw, "ng_nivel_general", "v_m"),  1)
    via <- round(last_val(ipp_raw, "ng_nivel_general", "v_ia"), 1)
    bs4ValueBox(
      value    = paste0(vm, " %"),
      subtitle = paste0("IPP - Mensual | Interanual: ", via, " %"),
      icon     = icon("arrow-up"), color = "success",
      footer   = div(ultimo_label)
    )
  })

  # ── Principal - lineas ───────────────────────────────────────────────────
  output$plot_principal_lineas <- renderHighchart({
    metrica <- input$metrica_principal
    rng     <- input$rng_principal
    col_val <- metrica_col(metrica)
    ytitle  <- metrica_ytitle(metrica)

    make_ng <- function(df, nombre, color) {
      s <- df %>%
        filter(nivel_general_aperturas == "ng_nivel_general",
               !is.na(.data[[col_val]])) %>%
        mutate(val = .data[[col_val]]) %>%
        filtrar_rng(rng)
      list(df = s, nombre = nombre, color = color)
    }

    series_list <- list(
      make_ng(ipim_raw, "IPIM", unname(COLORES_IDX["IPIM"])),
      make_ng(ipib_raw, "IPIB", unname(COLORES_IDX["IPIB"])),
      make_ng(ipp_raw,  "IPP",  unname(COLORES_IDX["IPP"]))
    )

    hc <- highchart() %>%
      hc_chart(type = "line") %>%
      hc_xAxis(type = "datetime",
               dateTimeLabelFormats = list(month = "%b %Y"),
               labels = list(style = list(color = "black", fontWeight = "bold"))) %>%
      hc_yAxis(title = list(text = ytitle,
                            style = list(color = "black", fontWeight = "bold")),
               gridLineWidth = 1,
               labels = list(style = list(color = "black"))) %>%
      hc_legend(enabled = TRUE,
                itemStyle = list(fontWeight = "bold", fontSize = "13px")) %>%
      hc_title(text  = paste0("IPIM / IPIB / IPP - ", metrica),
               style = list(fontSize = "15px", fontWeight = "bold")) %>%
      hc_subtitle(text  = ultimo_label,
                  style = list(fontSize = "11px", color = "#555")) %>%
      hc_tooltip(shared = TRUE,
                 pointFormat = paste0(
                   "<span style='color:{series.color}'>&#9679;</span> ",
                   "{series.name}: <b>{point.y:.2f}</b><br/>")) %>%
      hc_sipm_theme()

    for (sl in series_list) {
      hc <- hc %>% hc_add_series(
        data      = sl$df,
        type      = "line",
        hcaes(x   = periodo, y = val),
        name      = sl$nombre,
        color     = sl$color,
        lineWidth = 2.5,
        marker    = list(enabled = FALSE)
      )
    }
    hc
  })

  output$plot_principal_barras_m <- renderHighchart({
    bd <- tibble(
      label = c("IPIM", "IPIB", "IPP"),
      val   = c(last_val(ipim_raw, "ng_nivel_general", "v_m"),
                last_val(ipib_raw, "ng_nivel_general", "v_m"),
                last_val(ipp_raw,  "ng_nivel_general", "v_m")),
      color = unname(COLORES_IDX[c("IPIM", "IPIB", "IPP")])
    ) %>% mutate(val = round(val, 2), label = factor(label, levels = label))

    hchart(bd, "column", hcaes(x = label, y = val, color = color),
           showInLegend = FALSE,
           dataLabels = list(enabled = TRUE, format = "{point.y:.1f} %",
             style = list(fontSize = "13px", fontWeight = "bold", textOutline = "none"))) %>%
      hc_title(text = "Variacion Mensual",
               style = list(fontSize = "13px", fontWeight = "bold")) %>%
      hc_subtitle(text = ultimo_label, style = list(fontSize = "11px", color = "#555")) %>%
      hc_xAxis(labels = list(style = list(color = "black", fontWeight = "bold", fontSize = "14px"))) %>%
      hc_yAxis(title = list(text = "% Mensual", style = list(color = "black", fontWeight = "bold")),
               gridLineWidth = 0) %>%
      hc_tooltip(pointFormat = "<b>{point.y:.2f} %</b>") %>%
      hc_sipm_theme() %>% hc_legend(enabled = FALSE)
  })

  output$plot_principal_barras_ia <- renderHighchart({
    bd <- tibble(
      label = c("IPIM", "IPIB", "IPP"),
      val   = c(last_val(ipim_raw, "ng_nivel_general", "v_ia"),
                last_val(ipib_raw, "ng_nivel_general", "v_ia"),
                last_val(ipp_raw,  "ng_nivel_general", "v_ia")),
      color = unname(COLORES_IDX[c("IPIM", "IPIB", "IPP")])
    ) %>% mutate(val = round(val, 2), label = factor(label, levels = label))

    hchart(bd, "column", hcaes(x = label, y = val, color = color),
           showInLegend = FALSE,
           dataLabels = list(enabled = TRUE, format = "{point.y:.1f} %",
             style = list(fontSize = "13px", fontWeight = "bold", textOutline = "none"))) %>%
      hc_title(text = "Variacion Interanual",
               style = list(fontSize = "13px", fontWeight = "bold")) %>%
      hc_subtitle(text = ultimo_label, style = list(fontSize = "11px", color = "#555")) %>%
      hc_xAxis(labels = list(style = list(color = "black", fontWeight = "bold", fontSize = "14px"))) %>%
      hc_yAxis(title = list(text = "% Interanual", style = list(color = "black", fontWeight = "bold")),
               gridLineWidth = 0) %>%
      hc_tooltip(pointFormat = "<b>{point.y:.2f} %</b>") %>%
      hc_sipm_theme() %>% hc_legend(enabled = FALSE)
  })

  # ── IPIM ─────────────────────────────────────────────────────────────────
  output$plot_ipim_lineas    <- renderHighchart({
    build_lineas(ipim_raw, TOP_IPIM, input$metrica_ipim, input$rng_ipim, "IPIM")
  })
  output$plot_ipim_barras_m  <- renderHighchart({
    build_barras(ipim_raw, TOP_IPIM, "v_m",  "% Mensual",    "Variacion Mensual")
  })
  output$plot_ipim_barras_ia <- renderHighchart({
    build_barras(ipim_raw, TOP_IPIM, "v_ia", "% Interanual", "Variacion Interanual")
  })

  # ── IPIB ─────────────────────────────────────────────────────────────────
  output$plot_ipib_lineas    <- renderHighchart({
    build_lineas(ipib_raw, TOP_IPIB, input$metrica_ipib, input$rng_ipib, "IPIB")
  })
  output$plot_ipib_barras_m  <- renderHighchart({
    build_barras(ipib_raw, TOP_IPIB, "v_m",  "% Mensual",    "Variacion Mensual")
  })
  output$plot_ipib_barras_ia <- renderHighchart({
    build_barras(ipib_raw, TOP_IPIB, "v_ia", "% Interanual", "Variacion Interanual")
  })

  # ── IPP ──────────────────────────────────────────────────────────────────
  output$plot_ipp_lineas    <- renderHighchart({
    build_lineas(ipp_raw, TOP_IPP, input$metrica_ipp, input$rng_ipp, "IPP")
  })
  output$plot_ipp_barras_m  <- renderHighchart({
    build_barras(ipp_raw, TOP_IPP, "v_m",  "% Mensual",    "Variacion Mensual")
  })
  output$plot_ipp_barras_ia <- renderHighchart({
    build_barras(ipp_raw, TOP_IPP, "v_ia", "% Interanual", "Variacion Interanual")
  })
}

shinyApp(ui = ui, server = server)
