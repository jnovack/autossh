# jnovack/autossh

## v2.0.0

**Breaking Changes**
- Renamed lots of confusing variables names to less confusing variable names
    - `SSH_HOSTUSER` to `SSH_REMOTE_USER`
    - `SSH_HOSTNAME` to `SSH_REMOTE_HOST`
    - `SSH_TUNNEL_REMOTE` to `SSH_REMOTE_PORT`
    - `SSH_TUNNEL_HOST` to `SSH_TARGET_HOST`
    - `SSH_TUNNEL_LOCAL` to `SSH_TARGET_PORT`
- Docker Swarm compatibility
    - Renamed `SSH_KNOWN_HOSTS` to `SSH_KNOWN_HOSTS_FILE`

## v1.2.0

**Features**
- Image is now runnable as non-root user
- Allowed `autossh` variables to be configurable
    - `AUTOSSH_PIDFILE`
    - `AUTOSSH_POLL`
    - `AUTOSSH_GATETIME`
    - `AUTOSSH_FIRST_POLL`
    - `AUTOSSH_LOGLEVEL`
    - `AUTOSSH_LOGFILE`
- Allowed `ssh` variables to be configurable
    - `SERVER_ALIVE_INTERVAL`
    - `SERVER_ALIVE_COUNT_MAX`

## v1.0.0

**Features**
- Actually works.