FROM kaybenleroll/r_baseimage:base202007

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    byobu \
    less \
    libxml2-dev \
    zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && install2.r --error \
    caTools \
    knitr \
    poweRlaw \
    rprojroot \
    sp \
    xts


WORKDIR /tmp

RUN wget http://cas.uqam.ca/pub/R/src/contrib/CASdatasets_1.0-10.tar.gz \
  && R CMD INSTALL CASdatasets_1.0-10.tar.gz \
  && rm /tmp/*.tar.gz


