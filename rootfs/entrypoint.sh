#!/usr/bin/dumb-init /bin/sh
source version.sh
eval $(ssh-agent -s)
if [ -n "${SSH_KEY_FILE}" ]; then
    # Set up key file
    if [ ! -f "${SSH_KEY_FILE}" ]; then
        echo "[FATAL] No SSH Key file found"
        exit 1
    fi
    cat "${SSH_KEY_FILE}" | ssh-add -k -
else
    if [ -n "${SSH_KEY}" ]; then
        echo "${SSH_KEY}" | ssh-add -k -
    fi
fi

# If known_hosts is provided, STRICT_HOST_KEY_CHECKING=yes
# Default CheckHostIP=yes unless SSH_STRICT_HOST_IP_CHECK=false
STRICT_HOSTS_KEY_CHECKING=no
KNOWN_HOSTS=${SSH_KNOWN_HOSTS_FILE:=/known_hosts}
if [ -f "${KNOWN_HOSTS}" ]; then
    KNOWN_HOSTS_ARG="-o UserKnownHostsFile=${KNOWN_HOSTS} "
    if [ "${SSH_STRICT_HOST_IP_CHECK}" = false ]; then
        KNOWN_HOSTS_ARG="${KNOWN_HOSTS_ARG}-o CheckHostIP=no "
        echo "[WARN ] Not using STRICT_HOSTS_KEY_CHECKING"
    fi
    STRICT_HOSTS_KEY_CHECKING=yes
    echo "[INFO ] Using STRICT_HOSTS_KEY_CHECKING"
fi

# Add entry to /etc/passwd if we are running non-root
if [[ $(id -u) != "0" ]]; then
  USER="autossh:x:$(id -u):$(id -g):autossh:/tmp:/bin/sh"
  echo "[INFO ] Creating non-root-user = $USER"
  echo "$USER" >> /etc/passwd
fi

if [ ! -z "${SSH_BIND_IP}" ] && [ "${SSH_MODE}" = "-R" ]; then
    echo "[WARN ] SSH_BIND_IP requires GatewayPorts configured on the server to work properly"
fi

# Pick a random port above 32768
DEFAULT_PORT=$RANDOM
let "DEFAULT_PORT += 32768"

# Determine command line flags

# Log to stdout
echo "[INFO ] Using $(autossh -V)"
echo "[INFO ] Tunneling ${SSH_BIND_IP:=127.0.0.1}:${SSH_TUNNEL_PORT:=${DEFAULT_PORT}}" \
     " on ${SSH_REMOTE_USER:=root}@${SSH_REMOTE_HOST:=localhost}:${SSH_REMOTE_PORT}" \
     " to ${SSH_TARGET_HOST=localhost}:${SSH_TARGET_PORT:=22}"

COMMAND="autossh "\
"-M 0 "\
"-N "\
"-o StrictHostKeyChecking=${STRICT_HOSTS_KEY_CHECKING} ${KNOWN_HOSTS_ARG:=}"\
"-o ServerAliveInterval=${SSH_SERVER_ALIVE_INTERVAL:-10} "\
"-o ServerAliveCountMax=${SSH_SERVER_ALIVE_COUNT_MAX:-3} "\
"-o ExitOnForwardFailure=yes "\
"-t -t "\
"${SSH_MODE:=-R} ${SSH_BIND_IP}:${SSH_TUNNEL_PORT}:${SSH_TARGET_HOST}:${SSH_TARGET_PORT} "\
"-p ${SSH_REMOTE_PORT:=22} "\
"${SSH_REMOTE_USER}@${SSH_REMOTE_HOST}"

echo "[INFO ] # ${COMMAND}"

# Run command
exec ${COMMAND}
