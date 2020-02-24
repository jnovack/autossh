# docker-autossh

Highly customizable AutoSSH docker container

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
get to your target.

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

    target ---> |firewall| >--- remote ---< |firewall| <--- source
    10.1.1.101             [public.ip.addr]          192.168.1.101

The *target* (running **autossh**) connects up to the *remote* server and
keeps a tunnel alive so that *source* can proxy through *remote* and reach
resources on *target*.  Think of it as "long distance port-forwarding".

## Setup

To start, you will need to generate an SSH key on the Docker host. This will
ensure the key for the container is separate from your normal user key in the
event there is ever a need to revoke one or the other.

    $ ssh-keygen -t rsa -b 4096 -C "autossh"
    Generating public/private rsa key pair.
    Enter file in which to save the key (/home/jnovack/.ssh/id_rsa):
    Enter passphrase (empty for no passphrase):
    Enter same passphrase again:
    Your identification has been saved in /home/jnovack/.ssh/id_rsa.
    Your public key has been saved in /home/jnovack/.ssh/id_rsa.pub.
    The key fingerprint is:
    00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff jnovack@github
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

## Command-line Options

What would a docker container be without customization? I have an extensive
list of environment variables that can be set.

### Mounts

#### /id_rsa

Mount the key you generated within the **Setup** step, or set
`SSH_KEY_FILE`.

    -v /path/to/id_rsa:/id_rsa

#### /known_hosts

Mount the `known_hosts` file if you want to enable **STRICT_KEY_CHECKING**,
or set `SSH_KNOWN_HOSTS`.

    -v /path/to/known_hosts:/known_hosts

### Environment Variables

#### SSH_HOSTUSER

Specify the usename on the *remote* endpoint.  (Default: `root`)

#### SSH_HOSTNAME

Specify the address (ip preferred) of the *remote* endpoint. (Default:
`localhost`)

#### SSH_TUNNEL_REMOTE

Specify the port number on the *remote* endpoint which will serve as the
tunnel entrance. (Default: random > 32768)  If you do not want a new port
every time you restart **jnovack/autossh** you may wish to explicitly set
this.

This option reverses if you set `SSH_MODE` (see below).  To bind a local
forward tunnel to all interfaces, use an asterisk then the port desigation
(e.g. `*:2222`).

#### SSH_TUNNEL_HOST

Specify the address (ip preferred) of the *target*.

#### SSH_TUNNEL_LOCAL

Specify the port number on the *target* endpoint which will serve as the
tunnel exit, or destination service.  Typically this is `ssh` (port: 22),
however, you can tunnel other services such as redis (port: 6379),
elasticsearch (port: 9200) or good old http (port: 80) and https (port: 443).

#### SSH_STRICT_HOST_IP_CHECK

Set to `false` if you want the IP addresses of hosts to not be checked if
the `known_hosts` file is provided.  This can avoid issues for hosts with
dynamic IP addresses, but removes some additional protection against DNS
spoofing attacks.  Host IP Checking is enabled by default.

#### SSH_KEY_FILE

In the event you wish to store the key in Docker Secrets, you may wish to
set this to `/run/secrets/*secret-name*`

#### SSH_KNOWN_HOSTS

In the event you wish to store the `known_hosts` in Docker Secrets, you may
wish to set this to `/run/secrets/*secret-name*`

#### SSH_MODE

Defines how the tunnel will be set up:

- `-R` is default, remote forward mode.
- `-L` means local forward mode.

#### SERVER_ALIVE_INTERVAL

Sets a timeout interval in seconds after which if no data has been
received from the server, ssh(1) will send a message through the encrypted channel to
request a response from the server.

- `0` turns the option off.
- `10` is default for this image.

Additional details are available from [`ssh_config(5)`](https://linux.die.net/man/5/ssh_config)

#### SERVER_ALIVE_COUNT_MAX

Sets the threshold of alive messages after which the connection is terminated and reestablished.

- `3` is the default for this image.
- `SERVER_ALIVE_INTERVAL=0` turns this variable ineffective.

Additional details are available from [`ssh_config(5)`](https://linux.die.net/man/5/ssh_config)

#### Additional Environment variables

* [`autossh(1)`](https://linux.die.net/man/1/autossh)
* [`ssh_config(5)`](https://linux.die.net/man/5/ssh_config)

## Examples

### docker-compose.yml

In the top example `ssh-to-docker-host`, a tunnel will be made from the docker
container (aptly named `autossh-ssh-to-docker-host`) to the host running the
docker container.

To use, `ssh` to fake internet address `203.0.113.10:2222` and you will be
forwarded to `172.17.0.1:22` (the host running the docker container).

In the lower example, `ssh-to-lan-endpoint`, a tunnel will be made to a host
on the private LAN of the docker host.  `ssh`ing to fake internet address
`203.0.113.10:22222` will traverse through the docker container through the
docker host, and onto the private lan where the connection will terminate
`192.168.123.45:22`.

```yaml
version: '3.7'

services:
  ssh-to-docker-host:
    image: jnovack/autossh
    container_name: autossh-ssh-to-docker-host
    environment:
      - SSH_HOSTUSER=sshuser
      - SSH_HOSTNAME=203.0.113.10
      - SSH_TUNNEL_REMOTE=2222
      - SSH_TUNNEL_HOST=172.17.0.1
      - SSH_TUNNEL_LOCAL=22
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
      - SSH_HOSTUSER=sshuser
      - SSH_HOSTNAME=203.0.113.10
      - SSH_TUNNEL_REMOTE=22222
      - SSH_TUNNEL_HOST=198.168.123.45
      - SSH_TUNNEL_LOCAL=22
    restart: always
    volumes:
      - /etc/autossh/id_rsa:/id_rsa
    dns:
      - 8.8.8.8
      - 4.2.2.4
```

## ARM Support

For running on an ARM processor, you may use the tag `latest-arm32v7`

    docker pull jnovack/autossh:latest-arm32v7
