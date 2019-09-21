FROM alpine:latest

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
      org.opencontainers.image.url="https://hub.docker.com/r/jnovack/autossh/"

RUN apk --no-cache add \
	autossh \
	openssh-client \
	dumb-init
COPY /entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
