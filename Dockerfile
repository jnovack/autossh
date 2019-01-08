FROM alpine
MAINTAINER Ladislav Gazo <gazo@seges.sk>

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.license="MIT" \
      org.label-schema.name="lgazo/docker-autossh" \
      org.label-schema.url="https://hub.docker.com/r/lgazo/docker-autossh/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-type="Git" \
      org.label-schema.vcs-url="https://github.com/lgazo/docker-autossh"

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
    rm -rf /var/lib/apt/lists/*
