FROM alpine:latest

ARG BUILD_RFC3339
ARG COMMIT
ARG VERSION
LABEL org.opencontainers.image.ref.name="jnovack/autossh" \
      org.opencontainers.image.created=$BUILD_RFC3339 \
      org.opencontainers.image.authors="Justin J. Novack <jnovack@gmail.com>" \
      org.opencontainers.image.documentation="https://github.com/jnovack/docker-autossh/README.md" \
      org.opencontainers.image.description="Highly customizable AutoSSH docker container." \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/jnovack/docker-autossh" \
      org.opencontainers.image.revision=$COMMIT \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.url="https://hub.docker.com/r/jnovack/autossh/"

RUN \
  apk --no-cache add \
    autossh \
    net-tools \
    dumb-init && \
  chmod g+w /etc/passwd

ENV \
  AUTOSSH_PIDFILE=/tmp/autossh.pid \
  AUTOSSH_POLL=30 \
  AUTOSSH_GATETIME=30 \
  AUTOSSH_FIRST_POLL=30 \
  AUTOSSH_LOGLEVEL=0 \
  AUTOSSH_LOGFILE=/dev/stdout

COPY /entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
