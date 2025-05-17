# autossh

[![Docker](https://badgen.net/badge/jnovack/autossh/blue?icon=docker)](https://hub.docker.com/r/jnovack/autossh)
[![Github](https://badgen.net/badge/jnovack/autossh/purple?icon=github)](https://github.com/jnovack/autossh)

Highly customizable AutoSSH docker container.

## Overview

**jnovack/autossh** is a small lightweight (~15MB) image that attempts to
provide a secure way to establish an SSH Tunnel without including your keys in
the image itself or linking to the host.

There are thousands of *autossh* docker containers, why use this one? I hope
you find it easier to use. It is smaller, more customizable, an automated
build, easy to use, and I hope you learn something. I tried to follow standards
and established conventions where I could to make it easier to understand and
copy and paste lines from this project to others to grow your knowledge!

## Description

``autossh`` is a program to start a copy of ssh and monitor it, restarting it
as necessary should it die or stop passing traffic.

Before we begin, I want to define some terms.

- *local* - THIS docker container.

- *target* - The endpoint and ultimate destination of the tunnel.

- *remote* - The 'middle-man', or proxy server you are tunnelling through to
get to your *target*.

- *source* - The initial endpoint you are starting from that does not have
access to the *target* endpoint, but does have access to the *remote*
endpoint.

The *local* machine is USUALLY the same as the *target* but since we are using
Docker, we have to abstract out the *local* container from the *target*
endpoint where we want **autossh** to land. Normally, this is where
**autossh** is usually run from.

Typically, the *target* can be on a Home LAN segment without a publicly
addressible IP address; whereas the *remote* machine has an address that is
reachable by both *target* and *source*. And *source* can only reach *remote*.

```text
target ---> |firewall| >--- remote ---< |firewall| <--- source
10.1.1.101               203.0.113.10            192.168.1.101
```

The *target* (running **autossh**) connects up to the *remote* server and
keeps a tunnel alive so that *source* can proxy through *remote* and reach
resources on *target*.  Think of it as "long distance port-forwarding".

### Example

You are running `docker` on *target*, your home computer.  (Note: Linux Docker
hosts automatically create a `docker0` interface with `172.17.0.1` so the
containers can route to the host and out to other networks.  A container that
starts up could have the IP address `172.17.0.2`, for our example.)  You have a
Virtual Private Server (VPS) on the Internet that is accessible to all.  This
*local* docker container will make a connection to the *remote* VPS and tunnel
*remote* port 2222 to *target* port 22.  Any connection to *remote* port 2222
will actually be to the *target* server on port 22. This is known as a "reverse
tunnel".

```text
      TARGET_PORT                  REMOTE_PORT    TUNNEL_PORT
 target <--------------- local ------------> remote <--------------- source
 10.1.1.101           172.17.0.2          203.0.113.10        192.168.1.101
```

> The LOCAL (172.17.0.2) device connects to the REMOTE (203.0.113.10)
> REMOTE_PORT (:22) to create the tunnel on REMOTE (203.0.113.10) TUNNEL_PORT
> (:11111).
>
> The SOURCE (192.168.1.101) connects to the REMOTE (203.0.113.10) TUNNEL_PORT
> (:11111) to get to the TARGET (10.1.1.101) TARGET_PORT (:22).

By default, SSH server applications (such as OpenSSH, Dropbear, etc), only
permit connections to forwarded ports from the loopback interface
(`127.0.0.1`).

This means, you must be authenticated and connected the *remote* and use it as
a "jump point" (for a lack of a better term) before proceeding to connect to
the tunnel.

In the example above, from the *source*, you first have to open an SSH
connection to the *remote* (`203.0.113.10`), then you can continue to connect
to the *target* (`10.1.1.101`) by connecting to `127.0.0.1:TUNNEL_PORT`.
It is a two-step process.

To make this a one-step process (connecting from *source* to *target* via
*remote*), you must make some security changes on the *remote* (not-advised).
Please see the [SSH_BIND_IP](#SSH_BIND_IP) section below.

#### Disclaimer

By tunneling *remote* port 2222 to *target* port 22, you may be exposing
a home server (and by extension, your home network) to the Internet at large,
commonly known as "a bad thing(TM)".  Be sure to use appropriately use firewalls,
`fail2ban` scripts, non-root access, key-based authentication only, and other
security measures as necessary.

## Setup

To start, you will need to generate an SSH key on the Docker host. This will
ensure the key for the container is separate from your normal user key in the
event there is ever a need to revoke one or the other.

```text
$ ssh-keygen -t rsa -b 4096 -C "autossh" -f autossh_id_rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/home/jnovack/autossh_id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/jnovack/autossh_id_rsa.
Your public key has been saved in /home/jnovack/autossh_id_rsa.pub.
The key fingerprint is:
00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff autossh
The key's randomart image is:
+-----[ RSA 4096]-----+
|     _.-'''''-._     |
|   .'  _     _  '.   |
|  /   (_)   (_)   \  |
| |  ,           ,  | |
| |  \`.       .`/  | |
|  \  '.`'""'"`.'  /  |
|   '.  `'---'`  .'   |
|     '-._____.-'     |
+---------------------+
```

## Command-line Options

What would a docker container be without customization? I have an extensive
list of environment variables that can be set.

### Environment Variables

All the envrionment variables are prefaced with `SSH_` NOT because you are
required to tunnel SSH, but for ease of grouping.  The only SSH connection
that is required is from the LOCAL device to the REMOTE server.  However, if
you are interested in tunneling other protocols securely (e.g. mysql, redis,
mongodb) across networks with certificates, you may wish to consider my other
project [ambassador](https://hub.docker.com/r/jnovack/ambassador/).

#### SSH_REMOTE_USER

Specify the usename on the *remote* endpoint.  (Default: `root`)

#### SSH_REMOTE_HOST

Specify the address (ip preferred) of the *remote* endpoint. (Default:
`localhost`)

#### SSH_REMOTE_PORT

Specify the `ssh` port the *remote* endpoint to connect. (Default: `22`)

#### SSH_TUNNEL_PORT

Specify the port number on the *remote* endpoint which will serve as the
tunnel entrance. (Default: random > 32768)  If you do not want a new port
every time you restart **jnovack/autossh** you may wish to explicitly set
this.

This option reverses if you set `SSH_MODE` (see below).

#### SSH_TARGET_HOST

Specify the address (ip preferred) of the *target*.

#### SSH_TARGET_PORT

Specify the port number on the *target* endpoint which will serve as the
tunnel exit, or destination service.  Typically this is `ssh` (port: 22),
however, you can tunnel other services such as redis (port: 6379),
elasticsearch (port: 9200) or good old http (port: 80) and https (port: 443).

If you are interested in tunneling other protocols securely (e.g. mysql,
redis, mongodb) across networks via certificates you may wish to consider
my other project [ambassador](https://hub.docker.com/r/jnovack/ambassador/).

#### SSH_STRICT_HOST_IP_CHECK

Set to `false` if you want the IP addresses of hosts to **not** be checked if
the `known_hosts` file is provided.  This can help avoid issues for hosts with
dynamic IP addresses, but removes some additional protection against DNS
spoofing attacks.  Host IP Checking is enabled by default.

#### SSH_KEY_FILE

In the event you wish to store the key in Docker Secrets, you may wish to
set this to `/run/secrets/*secret-name*`

#### SSH_KNOWN_HOSTS_FILE

In the event you wish to store the `known_hosts` in Docker Secrets, you may
wish to set this to `/run/secrets/*secret-name*`

#### SSH_MODE

Defines how the tunnel will be set up:

- `-R` is default, remote forward mode.
- `-L` means local forward mode.

#### SSH_BIND_IP

You can define which IP address the tunnel will use to bind on *remote*
(SSH_MODE of `-R`) or *local* (SSH_MODE of `-L`). The default
is `127.0.0.1` only.

##### SSH_MODE of `-R` (default)

> [!WARNING]
> This process involves changing the security on the server
and will expose your *target* to additional networks and potentially the
Internet.  It is not recommended to do this procedure without taking
additional precautions.

Use of this option will NOT have an effect unless you properly configure the
`GatewayPorts` variable in your *remote* server's configuration file.  Please
see your SSH server documentation for proper set up.

##### SSH_MODE of `-L`

You may want to set this to `0.0.0.0` in order to bind your `SSH_TUNNEL_PORT`
to all interfaces on *local* side.

#### SSH_SERVER_ALIVE_INTERVAL

Sets a timeout interval in seconds after which if no data has been
received from the server, ssh(1) will send a message through the encrypted channel to
request a response from the server.

- `0` turns the option off.
- `10` is default for this image.

Additional details are available from [`ssh_config(5)`](https://linux.die.net/man/5/ssh_config)

#### SSH_SERVER_ALIVE_COUNT_MAX

Sets the threshold of alive messages after which the connection is terminated and reestablished.

- `3` is the default for this image.
- `SSH_SERVER_ALIVE_INTERVAL=0` makes this variable ineffective.

Additional details are available from [`ssh_config(5)`](https://linux.die.net/man/5/ssh_config)

#### SSH_OPTIONS

Sets additional parameters to `ssh` connection. Supports more than one parameter.

Examples:

- SSH_OPTIONS="-o StreamLocalBindUnlink=yes" for recreate socket if it exists
- SSH_OPTIONS="-o StreamLocalBindUnlink=yes -o UseRoaming=no" for multiple parameters

Additional details are available from [`ssh_config(5)`](https://linux.die.net/man/5/ssh_config)

#### Additional Environment variables

- [`autossh(1)`](https://linux.die.net/man/1/autossh)
- [`ssh_config(5)`](https://linux.die.net/man/5/ssh_config)

### Mounts

Mounts are optional, for simple usage.  It is far superior to use
[environment variables](#Environment_Variables) which can be stored in
configuration files and transported (and backed up!) easily.

#### /id_rsa

Mount the key you generated within the **Setup** step, or set
`SSH_KEY_FILE`.

```sh
-v /path/to/id_rsa:/id_rsa
```

#### /known_hosts

Mount the `known_hosts` file if you want to enable `StrictHostKeyChecking`,
or set `SSH_KNOWN_HOSTS_FILE`.

```sh
-v /path/to/known_hosts:/known_hosts
```

## Samples

### docker-compose.yml

In the top example `ssh-to-docker-host`, a tunnel will be made from the docker
container (aptly named `autossh-ssh-to-docker-host`) to the host running the
docker container.

To use, `ssh` to fake internet address `203.0.113.10:2222` and you will be
forwarded to `172.17.0.2:22` (the host running the docker container).

In the second example, `ssh-to-lan-endpoint`, a tunnel will be made to a host
on the private LAN of the docker host.  `ssh`ing to fake internet address
`203.0.113.10:22222` will traverse through the docker container through the
docker host, and onto the private lan where the connection will terminate
`192.168.123.45:22`.

Finally, in the third example, `ssh-local-forward-on-1234`, a local forward to
`198.168.123.45:22` will be created on the container, mapped to port `1234`.
The tunnel will be created via `203.0.113.10:22222`.

```yml
version: '3.7'

services:
  ssh-to-docker-host:
    image: jnovack/autossh
    container_name: autossh-ssh-to-docker-host
    environment:
      - SSH_REMOTE_USER=sshuser
      - SSH_REMOTE_HOST=203.0.113.10
      - SSH_REMOTE_PORT=2222
      - SSH_TARGET_HOST=172.17.0.2
      - SSH_TARGET_PORT=22
    restart: always
    volumes:
      - /etc/autossh/id_rsa:/id_rsa
    dns:
      - 8.8.8.8
      - 1.1.1.1

  ssh-to-lan-endpoint:
    image: jnovack/autossh
    container_name: autossh-ssh-to-lan-endpoint
    environment:
      - SSH_REMOTE_USER=sshuser
      - SSH_REMOTE_HOST=203.0.113.10
      - SSH_REMOTE_PORT=22222
      - SSH_TARGET_HOST=198.168.123.45
      - SSH_TARGET_PORT=22
    restart: always
    volumes:
      - /etc/autossh/id_rsa:/id_rsa
    dns:
      - 8.8.8.8
      - 4.2.2.4

  ssh-local-forward-on-1234:
    image: jnovack/autossh
    container_name: autossh-ssh-local-forward
    environment:
      - SSH_REMOTE_USER=sshuser
      - SSH_REMOTE_HOST=203.0.113.10
      - SSH_REMOTE_PORT=22222
      - SSH_BIND_IP=0.0.0.0
      - SSH_TUNNEL_PORT=1234
      - SSH_TARGET_HOST=198.168.123.45
      - SSH_TARGET_PORT=22
      - SSH_MODE=-L
    restart: always
    volumes:
      - /etc/autossh/id_rsa:/id_rsa
    dns:
      - 8.8.8.8
      - 4.2.2.4

```

## Multi-Arch Images

This image has the following architectures automatically built on Docker Hub.

- `amd64`
- `armv6` (e.g. Raspberry Pi Zero)
- `armv7` (e.g. Raspberry Pi 2 through 4)
- `arm64v8` (e.g. Amazon EC2 A1 Instances)
