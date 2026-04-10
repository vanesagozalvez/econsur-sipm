FROM rocker/shiny:4.3.3

# Dependencias del sistema
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# Paquetes R
RUN R -e "install.packages(c( \
    'shiny', \
    'bs4Dash', \
    'dplyr', \
    'tidyr', \
    'highcharter', \
    'viridis', \
    'lubridate', \
    'shinycssloaders', \
    'waiter' \
  ), repos='https://cloud.r-project.org/', dependencies=FALSE)"

# Copiar configuracion de Shiny Server
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# Copiar la aplicacion
COPY app.R       /srv/shiny-server/app.R
COPY data/       /srv/shiny-server/data/

# Puerto dinamico de Render
EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
