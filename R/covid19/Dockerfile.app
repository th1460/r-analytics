# Install Java
FROM openjdk:8

# Install Ubuntu packages
RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libsasl2-dev \
    r-base \
    r-base-dev

# Download and install Shiny Server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb

# Config Java
RUN sudo R CMD javareconf JAVA_HOME=$JAVA_HOME

# Install R packages that are required
RUN R -e "install.packages(c('shiny', 'bslib', 'magrittr', 'thematic', 'rJava', 'RJDBC', 'dbplyr', 'lubridate', 'leaflet', 'ggplot2'), repos='http://cran.rstudio.com/')"

# Copy configuration files into the Docker image
COPY shiny-server.conf  /etc/shiny-server/shiny-server.conf
COPY app.R /srv/shiny-server/

# Make the ShinyApp available at port 80
EXPOSE 8080

# Copy further configuration files into the Docker image
COPY shiny-server.sh /usr/bin/shiny-server.sh

# Jar file
COPY jars /srv/shiny-server/jars

# Environment variables
COPY .Renviron /srv/shiny-server/

RUN ["chmod", "+x", "/usr/bin/shiny-server.sh"]

CMD ["/usr/bin/shiny-server.sh"]