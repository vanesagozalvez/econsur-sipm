FROM rocker/shiny:4.3.3

ENV RSPM="https://packagemanager.posit.co/cran/__linux__/jammy/latest"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 👇 SIN type="binary"
RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages(c('dplyr','tidyr','lubridate'), dependencies=FALSE)"

RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages(c('shiny','shinycssloaders'), dependencies=FALSE)"

RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages(c('bs4Dash','waiter'), dependencies=FALSE)"

RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages('highcharter', dependencies=FALSE)"

RUN R -e "options(repos=c(RSPM=Sys.getenv('RSPM'))); \
    install.packages('viridis', dependencies=FALSE)"

COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

COPY app.R /srv/shiny-server/app.R
COPY data/ /srv/shiny-server/data/

EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
