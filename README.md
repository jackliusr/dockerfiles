# dockerfiles

Useful personal Dockerfiles and compose stacks for common software. The images
built here are used in company projects and my side projects.

Every directory is self-contained: build and run it from inside that directory.

## Contents

| Path                                             | Stack                                                        | Purpose                                                                                   |
| ------------------------------------------------ | ------------------------------------------------------------ | ----------------------------------------------------------------------------------------- |
| [dedecms](dedecms)                               | nginx 1.19.2, php:7.4-fpm, MySQL 5.7                         | DedeCMS (织梦 CMS) V5.75 SP1 UTF-8 development environment                                |
| [gnuhealth](gnuhealth)                           | Ubuntu 20.04 (or Debian 10), Python 3, Tryton/GNU Health 5.0 | Tryton + GNU Health server on uwsgi, plus an office image with LibreOffice                 |
| [mq-ha-demo](mq-ha-demo)                         | IBM MQ 10.0.1.0-r1                                           | Active/active queue-manager cluster demo with a shared cluster queue                      |
| [pg_cron](pg_cron)                               | postgres:16.4                                                | PostgreSQL with the `pg_cron` extension preloaded                                         |
| [trixie-libtiff](trixie-libtiff)                 | Debian trixie                                                | Debian trixie with a newer `libtiff` rebuilt from forky/sid (see its [README](trixie-libtiff/README.md)) |
| [tryton](tryton)                                 | tryton/tryton:5.0, PostgreSQL 13                             | Tryton 5.0 server plus compose stack that bootstraps the database with `trytond-admin`     |
| [docker-compose.yml](docker-compose.yml)         | PostgreSQL 16.4, Redis 6.2                                   | Root-level compose file for a local dev database and cache                                |

## Prerequisites

- Docker Engine with the Compose v2 plugin (`docker compose`)
- For `mq-ha-demo`: IBM MQ images are `linux/amd64` only, so other hosts need
  emulation (the compose file pins the platform)

## dedecms

PHP-FPM image for DedeCMS with the `gd` and `mysqli` extensions, wired to nginx
and MySQL by [dedecms/docker-compose.yml](dedecms/docker-compose.yml). The
application tree lives in [dedecms/uploads](dedecms/uploads) and is mounted as
`/code` into both the PHP and nginx containers; MySQL data is stored in
`dedecms/mysql_data` (git-ignored).

```bash
cd dedecms
docker compose up -d --build
# then open http://localhost/install/index.php to run the DedeCMS installer
```

`30_phpfpm_code_chown.sh` is mounted into the nginx image's
`/docker-entrypoint.d/` and hands `/code` to `www-data` on startup, so file
permissions work for both containers.
See [dedecms/README.md](dedecms/README.md) for notes on Xdebug and the
PEAR channel.

## gnuhealth

A Tryton/GNU Health 5.0 server image built from upstream components
(`trytond`, `proteus`, the accounting/stock/purchase modules and the SAO web
client). Two base variants are provided:

- `Dockerfile` — Ubuntu 20.04 (additionally installs `python-six`)
- `Dockerfile.debian` — Debian 10.6, otherwise identical

[entrypoint.sh](gnuhealth/entrypoint.sh) derives `TRYTOND_DATABASE_URI` from
`DB_USER`, `DB_PASSWORD`, `DB_HOSTNAME` and `DB_PORT` (defaulting to the old
`POSTGRES_ENV_*` variables), sources any `/docker-entrypoint-init.d/*.sh`, then
drops privileges to `trytond` via `gosu` and starts uwsgi on port 8000.
[install_health.sh](gnuhealth/install_health.sh) installs the `health_*` Tryton
modules into the image. [gnuhealth/office/Dockerfile](gnuhealth/office/Dockerfile)
extends the Tryton image with LibreOffice for document conversion.

```bash
cd gnuhealth
docker build -t gnuhealth:5.0 .
# or: docker build -f Dockerfile.debian -t gnuhealth:5.0 .
```

## mq-ha-demo

Two IBM MQ queue managers that are both full repositories of one cluster and both
host the same cluster queue, so producers and consumers can use either node (or
both) at once. One Dockerfile builds both nodes through build args, and the same
image runs the demo clients.

```bash
cd mq-ha-demo
docker compose up -d --build
docker compose run --rm producer      # put 10 messages over both nodes
docker compose logs -f consumer1 consumer2
```

The [compose.yaml](mq-ha-demo/compose.yaml) file also starts an nginx front door
for the web consoles, because the consoles only speak HTTPS with a self-signed
certificate that is regenerated on every start:

- <http://localhost:8080/ibmmq/console/> — `qm1`
- <http://localhost:8081/ibmmq/console/> — `qm2`
- <https://localhost:9443/ibmmq/console/>, <https://localhost:9444/ibmmq/console/> — direct HTTPS

Log in with `admin` / `passw0rd`. The demo consumers ship with
`STARTUP_DELAY_SECONDS=3600` so messages visibly accumulate first; set it to `0`
in [mq-ha-demo/compose.yaml](mq-ha-demo/compose.yaml) to drain the queue
immediately.

Clustering gives active/active *messaging*, not shared storage: messages on a
node stay unavailable while that node is down.

## pg_cron

`postgres:16.4` plus the `pg_cron` extension, installed for the running server's
major version. [setup-pg-cron.sh](pg_cron/setup-pg-cron.sh) runs on first
initialisation and appends `shared_preload_libraries='pg_cron'` and
`cron.database_name='postgres'` to `postgresql.conf`, so scheduled jobs are
created in the `postgres` database.

```bash
cd pg_cron
docker build -t pg-cron:16.4 .
docker run -d --name pg-cron -e POSTGRES_PASSWORD=postgres -p 5432:5432 pg-cron:16.4
```

## trixie-libtiff

Rebuilds the newest `tiff` source package from forky/sid against Debian trixie's
own libraries and installs only those binary packages, so the final image stays
trixie-based (pinning keeps every other package on trixie). Build args:
`DEBIAN_SUITE`, `TIFF_SUITES`, `TIFF_PACKAGES`.

```bash
cd trixie-libtiff
docker build -t trixie-libtiff .
```

The rationale for doing this instead of waiting for a `trixie-backports` upload
is discussed in [trixie-libtiff/README.md](trixie-libtiff/README.md).

## tryton

[tryton/Dockerfile](tryton/Dockerfile) adds `netcat` to `tryton/tryton:5.0` so the
compose stack can wait for PostgreSQL before initialising the database.

```bash
cd tryton
docker compose up -d
# trytond-admin runs once with --all to create/upgrade the gnuhealth database,
# then the server listens on http://localhost:8000
```

The stack pins the prebuilt `jackliusr/tryton:5.0` image; uncomment the `build:`
blocks in [tryton/docker-compose.yml](tryton/docker-compose.yml) to build it
locally instead. Passwords and the `trytond-admin` bootstrap email are set as
environment variables in that file.

## Root compose file

[docker-compose.yml](docker-compose.yml) starts PostgreSQL 16.4 and Redis 6.2 for
local development. The Postgres volume is declared `external`, so create it
first:

```bash
docker volume create TestFhirServerPostgres.AppHost-postgres-data
docker compose up -d
```

## Security note

Several compose files and the `mq-ha-demo` secret contain hard-coded demo
credentials, and `mq-ha-demo/secrets/mqAdminPassword` is committed to the
repository. Treat them as placeholders: replace them with your own values (or
real secrets management) before deploying anything outside a throwaway
environment.

