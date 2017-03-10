#!/bin/sh

touch /id_rsa
chmod 0400 /id_rsa

# Pick a random port above 32768
DEFAULT_PORT=$RANDOM
let "DEFAULT_PORT += 32768"
echo [INFO] Tunneling ${SSH_HOSTUSER:=root}@${SSH_HOSTNAME:=localhost}:${SSH_TUNNEL_REMOTE:=${DEFAULT_PORT}} to ${SSH_TUNNEL_HOST=localhost}:${SSH_TUNNEL_LOCAL:=22}

echo autossh \
 -M 0 \
 -o StrictHostKeyChecking=no \
 -o ServerAliveInterval=5 \
 -o ServerAliveCountMax=1 \
 -t -t \
 -i /id_rsa \
 -R ${SSH_TUNNEL_REMOTE}:${SSH_TUNNEL_HOST}:${SSH_TUNNEL_LOCAL} \
 -p ${SSH_HOSTPORT:=22} \
 ${SSH_HOSTUSER}@${SSH_HOSTNAME}

AUTOSSH_PIDFILE=/autossh.pid \
AUTOSSH_POLL=10 \
AUTOSSH_LOGLEVEL=0 \
AUTOSSH_LOGFILE=/dev/stdout \
autossh \
 -M 0 \
 -o StrictHostKeyChecking=no \
 -o ServerAliveInterval=5 \
 -o ServerAliveCountMax=1 \
 -t -t \
 -i /id_rsa \
 -R ${SSH_TUNNEL_REMOTE}:${SSH_TUNNEL_HOST}:${SSH_TUNNEL_LOCAL} \
 -p ${SSH_HOSTPORT:=22} \
 ${SSH_HOSTUSER}@${SSH_HOSTNAME}
