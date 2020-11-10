FROM node as builder-node
ENV SERIES 5.0
RUN npm install -g bower
RUN curl https://downloads.tryton.org/${SERIES}/tryton-sao-last.tgz | tar zxf - -C /
RUN cd /package && bower install --allow-root

FROM ubuntu:20.04 
LABEL maintainer="Tryton <foundation@tryton.org>" \
    org.label-schema.name="Tryton" \
    org.label-schema.url="http://www.tryton.org/" \
    org.label-schema.vendor="Tryton" \
    org.label-schema.version="5.0" \
    org.label-schema.schema-version="1.0"
ARG DEBIAN_FRONTEND=noninteractive
ENV SERIES 5.0
ENV LANG C.UTF-8

RUN groupadd -r trytond \
    && useradd --no-log-init -r -d /var/lib/trytond -m -g trytond trytond \
    && mkdir /var/lib/trytond/db && chown trytond:trytond /var/lib/trytond/db \
    && mkdir /var/lib/trytond/www \
    && mkdir -p /etc/python3 \
    && echo "[DEFAULT]\nbyte-compile = standard, optimize" \
        > /etc/python3/debian_config

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libffi-dev \
        libssl-dev \
        python-six  \
        python3 \
        python3-bcrypt \
        python3-caldav \
        python3-dateutil \
        python3-dev \
        python3-genshi \
        python3-html2text \
        python3-ldap \
        python3-lxml \
        python3-magic \
        python3-ofxparse \
        python3-pip \
        python3-polib \
        python3-psycopg2 \
        python3-pypdf2 \
        python3-pysimplesoap \
        python3-qrcode \
        python3-relatorio \
        python3-requests \
        python3-setuptools \
        python3-simpleeval \
        python3-stdnum \
        python3-tz \
        python3-vobject \
        python3-werkzeug \
        python3-wrapt \
        python3-zeep \
        uwsgi \
        uwsgi-plugin-python3 \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --install-option="-O1" \
    "trytond == ${SERIES}.*" \
    "proteus == ${SERIES}.*" \
    "python-barcode" \
    "Pillow" \
    "python-sql" \
    "configparser" \
    "pywebdav3-gnuhealth" \
    "numpy" \
    "unoconv" \
    "passlib" \
    "beren" \
    "poetry" \
    "pendulum" \
    "matplotlib" \
    #&& for module in `curl https://downloads.tryton.org/${SERIES}/modules.txt`; do \
  && for module in account \
  account_invoice \
  account_product \
  company \
  country \
  currency \
  party \
  product \
  stock \
  stock_lot \
  purchase \
  account_invoice_stock \
  stock_supply \
  purchase_request ; \
  do \
        pip3 install --no-cache-dir --install-option="-O1" "trytond_${module} == ${SERIES}.*"; \
        done \
    && pip3 install --no-cache-dir --install-option="-O1" phonenumbers python-stdnum[SOAP] pygal

COPY --from=builder-node /package /var/lib/trytond/www
COPY entrypoint.sh /
COPY trytond.conf /etc/trytond.conf
COPY uwsgi.conf /etc/uwsgi.conf

EXPOSE 8000

VOLUME ["/var/lib/trytond/db"]
ENV TRYTOND_CONFIG=/etc/trytond.conf
USER trytond
ENTRYPOINT ["/entrypoint.sh"]
CMD ["uwsgi", "--ini", "/etc/uwsgi.conf"]
