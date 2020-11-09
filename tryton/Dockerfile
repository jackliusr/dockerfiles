FROM tryton/tryton:5.0
LABEL maintainer="Jack Liu S.R.<jackliusr@gmail.com>"

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  netcat \
  && apt-get clean \
  &&   rm -rf /var/lib/apt/lists/*
USER trytond
