FROM docker.io/library/postgres:16.4

RUN apt-get update && \
    apt-get install -y \
    cron \
    postgresql-`postgres -V | awk '{print $3}' | awk -F. '{print $1}'`-cron

COPY setup-pg-cron.sh /docker-entrypoint-initdb.d/
