FROM alpine:3.9.4
MAINTAINER Justin J. Novack <jnovack@gmail.com>

ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.ref.name="jnovack/autossh" \
      org.opencontainers.image.created=$BUILD_RFC3339 \
      org.opencontainers.image.authors="Justin J. Novack <jnovack@gmail.com>" \
      org.opencontainers.image.documentation="https://github.com/jnovack/docker-autossh/README.md" \
      org.opencontainers.image.description="Highly customizable AutoSSH docker container." \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/jnovack/docker-autossh" \
      org.opencontainers.image.revision=$COMMIT \
      org.opencontainers.image.url="https://hub.docker.com/r/jnovack/docker-autossh/"

ENTRYPOINT ["/entrypoint.sh"]
ADD /entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ENV \
    TERM=xterm \
    AUTOSSH_LOGFILE=/dev/stdout \
    AUTOSSH_GATETIME=30         \
    AUTOSSH_POLL=10             \
    AUTOSSH_FIRST_POLL=30       \
    AUTOSSH_LOGLEVEL=1

RUN apk update && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    apk add --update autossh && \
    apk add --update openssh-client && \
    rm -rf /var/lib/apt/lists/*
