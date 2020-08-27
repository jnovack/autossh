FROM alpine:latest

ARG APPLICATION="myapp"
ARG BUILD_RFC3339="1970-01-01T00:00:00Z"
ARG REVISION="local"
ARG DESCRIPTION="no description"
ARG PACKAGE="user/repo"
ARG VERSION="dirty"

LABEL org.opencontainers.image.ref.name="${PACKAGE}" \
  org.opencontainers.image.created=$BUILD_RFC3339 \
  org.opencontainers.image.authors="Justin J. Novack <jnovack@gmail.com>" \
  org.opencontainers.image.documentation="https://github.com/${PACKAGE}/README.md" \
  org.opencontainers.image.description="${DESCRIPTION}" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.source="https://github.com/${PACKAGE}" \
  org.opencontainers.image.revision=$REVISION \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.url="https://hub.docker.com/r/${PACKAGE}/"

RUN \
  apk --no-cache add \
    autossh \
    dumb-init && \
  chmod g+w /etc/passwd

ENV \
  AUTOSSH_PIDFILE=/tmp/autossh.pid \
  AUTOSSH_POLL=30 \
  AUTOSSH_GATETIME=30 \
  AUTOSSH_FIRST_POLL=30 \
  AUTOSSH_LOGLEVEL=0 \
  AUTOSSH_LOGFILE=/dev/stdout

ENV \
  APPLICATION="${APPLICATION}" \
  BUILD_RFC3339="${BUILD_RFC3339}" \
  REVISION="${REVISION}" \
  DESCRIPTION="${DESCRIPTION}" \
  PACKAGE="${PACKAGE}" \
  VERSION="${VERSION}"

COPY ./rootfs/entrypoint.sh /entrypoint.sh
COPY ./rootfs/version.sh /version.sh

ENTRYPOINT [ "/entrypoint.sh" ]
