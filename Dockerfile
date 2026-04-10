FROM rocker/shiny:4.3.3

# ── Repositorio RSPM: binarios pre-compilados para Ubuntu 22.04 ──────────────
# Esto evita compilar desde fuente y reduce drásticamente RAM y tiempo de build
ENV RSPM="https://packagemanager.posit.co/cran/__linux__/jammy/latest"

# ── Dependencias de sistema mínimas (solo las estrictamente necesarias) ───────
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Paquetes R desde RSPM en binario ─────────────────────────────────────────
# SIN dependencies=TRUE -> solo dependencias directas e indispensables
# Instalados en bloques separados para aprovechar cache de capas Docker

RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages(c('dplyr','tidyr','lubridate'), \
    type='binary', dependencies=FALSE)"

RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages(c('shiny','shinycssloaders'), \
    type='binary', dependencies=FALSE)"

RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages(c('bs4Dash','waiter'), \
    type='binary', dependencies=FALSE)"

RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages('highcharter', \
    type='binary', dependencies=FALSE)"

RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages('viridis', \
    type='binary', dependencies=FALSE)"

# ── Configuracion Shiny Server ────────────────────────────────────────────────
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# ── Aplicacion ────────────────────────────────────────────────────────────────
COPY app.R   /srv/shiny-server/app.R
COPY data/   /srv/shiny-server/data/

EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
