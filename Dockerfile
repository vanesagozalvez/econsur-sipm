FROM rocker/shiny:4.3.3

ENV RSPM="https://packagemanager.posit.co/cran/__linux__/jammy/latest"
ENV DEBIAN_FRONTEND=noninteractive

# Dependencias mínimas del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ⚠️ IMPORTANTE: instalar TODO junto + dependencies=TRUE
RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages(c( \
      'shiny', \
      'bs4Dash', \
      'dplyr', \
      'tidyr', \
      'highcharter', \
      'viridis', \
      'lubridate', \
      'shinycssloaders', \
      'waiter' \
    ), dependencies=TRUE)"

# Copiar configuración
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# Copiar app
COPY app.R /srv/shiny-server/app.R
COPY data/ /srv/shiny-server/data/

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]


