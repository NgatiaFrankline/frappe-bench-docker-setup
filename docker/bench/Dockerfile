ARG BENCH_VERSION=v5.31.0

FROM frappe/bench:${BENCH_VERSION} AS bench
LABEL org.opencontainers.image.title="Bench Image"
LABEL org.opencontainers.image.description="Development bench image for Frappe apps from frappe/bench"
LABEL org.opencontainers.image.version="${BENCH_VERSION}"
ENV TZ=Africa/Nairobi

USER root

# Install packages
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      cron \
      sudo \
      procps \
      netcat-openbsd \
      supervisor \
    && rm -rf /var/lib/apt/lists/*

COPY scripts /scripts
RUN set -ex \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone

RUN set -ex \
    && mkdir -p /workspace /backup /logs \
    && chown -R frappe:frappe /workspace /scripts /backup /logs \
    && chmod -R 775 /scripts \
    && chmod +x /scripts/*.sh

# PASSWORDLESS SUDO
RUN set -ex \
    && echo "frappe ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/frappe \
    && chmod 0440 /etc/sudoers.d/frappe

USER frappe
WORKDIR /workspace
EXPOSE 8000-8005 9000-9005 6787
ENTRYPOINT ["/scripts/entrypoint.sh"]


