FROM rocker/shiny:4.3.3

ENV RSPM="https://packagemanager.posit.co/cran/__linux__/jammy/latest"
ENV DEBIAN_FRONTEND=noninteractive

# System dependencies (includes V8 for highcharter)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libv8-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages(c( \
      'shiny', \
      'bs4Dash', \
      'dplyr', \
      'tidyr', \
      'tibble', \
      'highcharter', \
      'viridis', \
      'lubridate', \
      'shinycssloaders', \
      'waiter' \
    ), dependencies=TRUE)"

# Config
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# App in its own subfolder so Shiny Server detects it correctly
RUN mkdir -p /srv/shiny-server/sipm
COPY app.R /srv/shiny-server/sipm/app.R
COPY data/  /srv/shiny-server/sipm/data/

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
