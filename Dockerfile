# work from latest LTS ubuntu release
FROM ubuntu:18.04

# set variables
ENV r_version 3.6.1

# run update
RUN apt-get update -y && apt-get install -y \
  gfortran \
  libreadline-dev \
  libpcre3-dev \
  libcurl4-openssl-dev \
  build-essential \
  zlib1g-dev \
  libbz2-dev \
  liblzma-dev \
  openjdk-8-jdk \
  wget \
  libssl-dev \
  libxml2-dev \
  libnss-sss

# change working dir
WORKDIR /usr/local/bin

# install R
RUN wget https://cran.r-project.org/src/base/R-3/R-${r_version}.tar.gz
RUN tar -zxvf R-${r_version}.tar.gz
WORKDIR /usr/local/bin/R-${r_version}
RUN ./configure --prefix=/usr/local/ --with-x=no
RUN make
RUN make install

# install R packages
RUN R --vanilla -e "source('https://bioconductor.org/biocLite.R'); biocLite('snpStats')"
RUN R --vanilla -e "install.packages(c('dplyr', 'GenomicTools'), repos='http://cran.us.r-project.org')"

# copy any one-off R scripts over
RUN mkdir -p /opt/scripts/R
COPY scripts/var_bp_from_GTF.R /opt/scripts/R
