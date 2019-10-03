#!/usr/bin/dumb-init /bin/sh

# Set up key file
KEY_FILE=${SSH_KEY_FILE:=/id_rsa}
if [ ! -f "${KEY_FILE}" ]; then
    echo "[ERROR] No SSH Key file found"
    exit 1
fi
eval $(ssh-agent -s)
cat "${SSH_KEY_FILE}" | ssh-add -k -

# Set up known_hosts file if needed
STRICT_HOSTS_KEY_CHECKING=no
KNOWN_HOSTS=${SSH_KNOWN_HOSTS:=/known_hosts}
if [ -f "${KNOWN_HOSTS}" ]; then
    KNOWN_HOSTS_ARG="-o UserKnownHostsFile=${KNOWN_HOSTS} "
    if [ -n ${SSH_NO_STRICT_HOST_IP_CHECK+x} ]; then
        KNOWN_HOSTS_ARG="${KNOWN_HOSTS_ARG}-o CheckHostIP=no "
    fi
    STRICT_HOSTS_KEY_CHECKING=yes
fi

# Pick a random port above 32768
DEFAULT_PORT=$RANDOM
let "DEFAULT_PORT += 32768"

# Determine command line flags
INFO_TUNNEL_SRC="${SSH_HOSTUSER:=root}@${SSH_HOSTNAME:=localhost}:${SSH_TUNNEL_REMOTE:=${DEFAULT_PORT}}"
INFO_TUNNEL_DEST="${SSH_TUNNEL_HOST=localhost}:${SSH_TUNNEL_LOCAL:=22}"
COMMAND="autossh "\
"-M 0 "\
"-N "\
"-o StrictHostKeyChecking=${STRICT_HOSTS_KEY_CHECKING} ${KNOWN_HOSTS_ARG:=}"\
"-o ServerAliveInterval=10 "\
"-o ServerAliveCountMax=3 "\
"-o ExitOnForwardFailure=yes "\
"-t -t "\
"${SSH_MODE:=-R} ${SSH_TUNNEL_REMOTE}:${SSH_TUNNEL_HOST}:${SSH_TUNNEL_LOCAL} "\
"-p ${SSH_HOSTPORT:=22} "\
"${SSH_HOSTUSER}@${SSH_HOSTNAME}"

# Log to stdout
echo "[INFO] Using $(autossh -V)"
echo "[INFO] Tunneling ${INFO_TUNNEL_SRC} to ${INFO_TUNNEL_DEST}"
echo "> ${COMMAND}"

# Run command
AUTOSSH_PIDFILE=/autossh.pid \
AUTOSSH_POLL=30 \
AUTOSSH_GATETIME=30 \
AUTOSSH_FIRST_POLL=30 \
AUTOSSH_LOGLEVEL=0 \
AUTOSSH_LOGFILE=/dev/stdout \
exec ${COMMAND}
