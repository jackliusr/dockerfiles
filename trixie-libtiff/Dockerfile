# syntax=docker/dockerfile:1
#
# Debian trixie with libtiff backported from the newer Debian suites
# (forky / sid). The source package is rebuilt against trixie's own
# libraries so the resulting binaries only depend on trixie packages.
#
#   docker build -t trixie-libtiff .
#   docker build --build-arg TIFF_SUITES="sid" -t trixie-libtiff .
#   docker build --build-arg TIFF_PACKAGES="libtiff6 libtiffxx6 libtiff-dev" .
#
# Build args:
#   DEBIAN_SUITE   base suite (default: trixie)
#   TIFF_SUITES    suites to take the tiff source package from
#                  (default: "forky sid"; the newest version wins)
#   TIFF_PACKAGES  packages to install in the final image
#                  (default: "libtiff6 libtiffxx6")

ARG DEBIAN_SUITE=trixie
ARG TIFF_SUITES="forky sid"
ARG TIFF_PACKAGES="libtiff6 libtiffxx6"

# ---------------------------------------------------------------------------
# Stage 1: rebuild the newer tiff source package on top of trixie
# ---------------------------------------------------------------------------
FROM debian:${DEBIAN_SUITE} AS tiff-backport

ARG DEBIAN_SUITE
ARG TIFF_SUITES

ENV DEBIAN_FRONTEND=noninteractive

# Add deb-src for trixie (needed by build-dep) and deb/deb-src for the
# newer suites. forky/sid are only used as a source of the tiff package;
# the pinning below keeps every other package on trixie.
RUN set -eux; \
    printf 'Types: deb-src\nURIs: http://deb.debian.org/debian\nSuites: %s %s-updates\nComponents: main\nSigned-By: /usr/share/keyrings/debian-archive-keyring.pgp\n' \
        "${DEBIAN_SUITE}" "${DEBIAN_SUITE}" \
        > "/etc/apt/sources.list.d/${DEBIAN_SUITE}-src.sources"; \
    for suite in ${TIFF_SUITES}; do \
        printf 'Types: deb deb-src\nURIs: http://deb.debian.org/debian\nSuites: %s\nComponents: main\nSigned-By: /usr/share/keyrings/debian-archive-keyring.pgp\n' \
            "${suite}" > "/etc/apt/sources.list.d/${suite}.sources"; \
    done

# Debian ships stable/testing/unstable all at priority 500, so without pins
# apt would happily pull newer forky/sid libraries. Pin trixie (and its
# security/updates suites) high and the backport suites low, so build
# dependencies - and therefore the produced binaries - stay trixie-based.
RUN set -eux; \
    { \
        echo 'Package: *'; \
        echo "Pin: release n=${DEBIAN_SUITE}"; \
        echo 'Pin-Priority: 990'; \
        echo; \
        echo 'Package: *'; \
        echo "Pin: release n=${DEBIAN_SUITE}-updates"; \
        echo 'Pin-Priority: 990'; \
        echo; \
        echo 'Package: *'; \
        echo "Pin: release n=${DEBIAN_SUITE}-security"; \
        echo 'Pin-Priority: 990'; \
        for suite in ${TIFF_SUITES}; do \
            echo; \
            echo 'Package: *'; \
            echo "Pin: release n=${suite}"; \
            echo 'Pin-Priority: 100'; \
        done; \
    } > /etc/apt/preferences.d/99-tiff-backport.pref

WORKDIR /usr/src

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential dpkg-dev; \
    apt-get build-dep -y tiff

# Take the newest tiff source version offered by TIFF_SUITES and build
# binary packages from it. `apt-get source` needs an explicit version
# because the trixie candidate (pinned) is still the older one.
RUN set -eux; \
    version="$(apt-cache madison tiff \
        | awk -F'|' -v suites="${TIFF_SUITES}" '{ \
              v = $2; gsub(/^[ \t]+|[ \t]+$/, "", v); \
              n = split(suites, s, " "); \
              for (i = 1; i <= n; i++) \
                  if ($3 ~ ("[ /]" s[i] "/")) { print v; break } \
          }' \
        | sort -V | tail -n1)"; \
    test -n "${version}"; \
    echo "Backporting tiff ${version} from ${TIFF_SUITES}"; \
    apt-get source "tiff=${version}"; \
    cd "$(ls -d /usr/src/tiff-[0-9]*/)"; \
    dpkg-buildpackage -b -uc -us -j"$(nproc)"

# ---------------------------------------------------------------------------
# Stage 2: runtime image - trixie plus the freshly built libtiff packages
# ---------------------------------------------------------------------------
FROM debian:${DEBIAN_SUITE}

ARG TIFF_PACKAGES

# The runtime stage has no forky/sid repositories, so this install fails if a
# backported package ever needs something trixie does not provide.
COPY --from=tiff-backport /usr/src/*.deb /tmp/tiff-debs/

RUN set -eux; \
    debs=''; \
    for pkg in ${TIFF_PACKAGES}; do \
        debs="${debs} $(ls /tmp/tiff-debs/${pkg}_*.deb)"; \
    done; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
        apt-get install -y --no-install-recommends ${debs}; \
    rm -rf /tmp/tiff-debs /var/lib/apt/lists/*; \
    for pkg in ${TIFF_PACKAGES}; do dpkg-query -W "${pkg}"; done; \
    ldconfig -p | grep -E 'libtiff(xx)?\.so\.6 '
