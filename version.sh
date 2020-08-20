#!/bin/sh

# A "common-courtesy" file inspired by @gurneyalex
#  - Information on current version.
#  - Deprecation warnings for future versions.

if [ ! -z $SSH_TUNNEL_HOST ]; then
    echo "[WARN ] SSH_TUNNEL_HOST will be deprecated in v2.0"
fi

if [ ! -z $SSH_TUNNEL_LOCAL ]; then
    echo "[WARN ] SSH_TUNNEL_LOCAL will be deprecated in v2.0"
fi

if [ ! -z $SSH_TUNNEL_REMOTE ]; then
    echo "[WARN ] SSH_TUNNEL_REMOTE will be deprecated in v2.0"
fi

if [ ! -z $SSH_HOSTUSER ]; then
    echo "[WARN ] SSH_HOSTUSER will be deprecated in v2.0"
fi

if [ ! -z $SSH_HOSTNAME ]; then
    echo "[WARN ] SSH_HOSTNAME will be deprecated in v2.0"
fi

if [ ! -z $SSH_HOSTPORT ]; then
    echo "[WARN ] SSH_HOSTPORT will be deprecated in v2.0"
fi

if [ ! -z $SSH_KNOWN_HOSTS ]; then
    echo "[WARN ] SSH_KNOWN_HOSTS will be deprecated in v2.0"
fi
