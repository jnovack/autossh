#!/bin/sh

# A "common-courtesy" file inspired by @gurneyalex
#  - Information on current version.
#  - Deprecation warnings for future versions.

echo "${PACKAGE} ${VERSION} revision ${REVISION} built ${BUILD_RFC3339}"

if [ -n "$SSH_TUNNEL_HOST" ]; then
    echo "[WARN ] SSH_TUNNEL_HOST is deprecated, please use SSH_TARGET_HOST"
    WARN=true
fi

if [ -n "$SSH_TUNNEL_LOCAL" ]; then
    echo "[WARN ] SSH_TUNNEL_LOCAL is deprecated, please use SSH_TARGET_PORT"
    WARN=true
fi

if [ -n "$SSH_TUNNEL_REMOTE" ]; then
    echo "[WARN ] SSH_TUNNEL_REMOTE is deprecated, please use SSH_TUNNEL_PORT"
    WARN=true
fi

if [ -n "$SSH_HOSTUSER" ]; then
    echo "[WARN ] SSH_HOSTUSER is deprecated, please use SSH_REMOTE_USER"
    WARN=true
fi

if [ -n "$SSH_HOSTNAME" ]; then
    echo "[WARN ] SSH_HOSTNAME is deprecated, please use SSH_REMOTE_HOST"
    WARN=true
fi

if [ -n "$SSH_HOSTPORT" ]; then
    echo "[WARN ] SSH_HOSTPORT is deprecated, please use SSH_REMOTE_PORT"
    WARN=true
fi

if [ -n "$SSH_KNOWN_HOSTS" ]; then
    echo "[WARN ] SSH_KNOWN_HOSTS is deprecated, please use SSH_KNOWN_HOSTS_FILE"
    WARN=true
fi

if [ -n "$WARN" ]; then
    echo "[WARN ] You are using some deprecated variables, future versions will remove them."
fi

# Exit if there are any fatal errors from version mismatches.
if [ -n "$FATAL" ]; then
    exit 1
fi
