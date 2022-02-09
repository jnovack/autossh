# Testing

The file `docker-compose.test.yml` is specific to Docker Hub to perform
[automated repository tests](https://docs.docker.com/docker-hub/builds/automated-testing/),
but we can use the file in the same manner to perform local testing.  It also
serves as an example for a complete end-to-end working environment without
having to compromise a server or your own keys for testing.

In an effort to teach, grow and "level-up", I will try my best to explain the
commands and the reasons behind them.  This should make it easier for someone
to correct my testing (in the event I am doing it wrong), or make it easier for
someone to utilize these ideas in a future project.

## Terminology

> The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
> "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
> document are to be interpreted as described in BCP 14,
> [RFC2119](https://tools.ietf.org/html/rfc2119).

## Overview

Just a reminder, here is a text-based overview of a complete end-to-end setup.

```text
      TARGET_PORT                  REMOTE_PORT    TUNNEL_PORT
 target <--------------- local ------------> remote <--------------- source
 203.0.113.100       203.0.113.111        203.0.113.10        203.0.113.200
```

> The LOCAL (203.0.113.111) device connects to the REMOTE (203.0.113.10)
> device on REMOTE_PORT (:22) to create the tunnel on REMOTE (203.0.113.10) at
> TUNNEL_PORT (:11111).
>
> The SOURCE (203.0.113.200) connects to the REMOTE (203.0.113.10) device
> TUNNEL_PORT (:11111) to get to the TARGET (203.0.113.100) TARGET_PORT (:22).

There is a similar setup for local-with-env which is living on 203.0.113.112
and setting up a tunnel on REMOTE (203.0.113.10) on port :11112. This setup
just passing the SSH key using an environment variable instead of a file.

### 203.0.113.0/24

Do not be alarmed, the address space `203.0.113.0/24` is not actually on the
Internet.  It is "TEST-NET-3" as defined by
[RFC5737](https://tools.ietf.org/html/rfc5737), specifically for use in
documentation.  These subnets SHOULD NOT be routed.

This makes them safe for things like documentation, or in this case, spawning
an entire network so that all containers can talk to each other.

I did not want to rely on hostnames or other IP ranges to avoid collisions, so
I chose a very obscure network.  Docker by default uses the `172.16.0.0/12`
range, but any organization might use `10.0.0.0/8` or `192.168.0.0/16`.

### Dockerfile.openssh

A minimal Alpine linux docker container with `openssh` and `openssh-client`
packages is referenced by `bootloader`, `remote`, `target` and `sut`.  This
was just an easy way to make good use of caching images rather than build each
container and download files four times.

#### dumb-init

`dumb-init` is included so that `docker-compose` can properly send a `SIGTERM`
signal to the `bootloader` service (which is running `sleep`, which does not
respond to signals).  This permits the test to complete immediately rather than
having to wait the default kill timeout in Docker (10 seconds) before completing
the test.

### sshkeys volume

The ssh keys must be shared with all the containers, so the first thing to do is
set up a volume.  The `sshkeys` volume is mounted differently in each container.
It will contain the following files:

- id_rsa - Private Key
- id_rsa.pub - Public Key
- authorized_keys - authorized_keys file for root user
- remote.txt - ready file for the **REMOTE** service
- target.txt - ready file for the **TARGET** service

On **REMOTE** and **TARGET**, this volume is mounted in `/root/.ssh` so we
can utilize the keys properly.  On **LOCAL**, we only care about the
`id_rsa.pub` file; and on **SOURCE**, we need `id_rsa`, so these files can
be anywhere as, but for simplicity, we put them in `/opt/`.

**docker-compose** has no method of knowing when a container is ready, so
we need a way to know when to actually test.  The "ready files" being created
is the queue for the `sut` service (the **SOURCE**) to start the test.

This prevents **SOURCE** from exiting early with a failure when it cannot
connect to **REMOTE** on `REMOTE_PORT` because it didn't come up yet.

## Services

Docker Hub only starts the `sut` service (stands for "System Under Test") and
any other services listed under `depends_on` for this service. Since
`depends_on` works backwards, we have `sut` start all of the other services.

Additionally, Docker Hub (and `make docker-test`) test for the exit condition
of the `sut` container; so we have it exit successfully (`0`) when we have a
successful test.  At that point we are sure that our `autossh` container is
working.  We fail the test on any other exit code.

We cannot test the `autossh` container within the context of itself as we have
no mechanism to do so.  We must test it externally, but, more importantly, we
SHOULD test it externally. This means we need a *SOURCE*, a *TARGET* and a
*REMOTE* if we want to be a valid test.

### bootloader

The purpose of the `bootloader` service is to create the keys that will be used
by all of the other containers.

I tried putting these commands in other containers (`sut` and `local`) but
`sut` relies on `local` being fully up, and `local` needs the keys before `sut`
can start.  This wound up being a race condition which sometimes failed the
testing.

The `bootloader` service does not exit after it is complete because using
`--exit-code-from sut` implies `--abort-on-container-exit`.  This means the
`bootloader` service will have to hang around for some time.  I specifically
chose not to use `tail -f /dev/null` or something running indefinitely because
I wanted to fail out at SOME point.  I wanted a timeout.  By using `sleep 300`
it gives me 5 minutes (which is probably WAAAY too long) to run my test before
this container exits and thus fails the test.

If everything is good, this container SHOULD NOT hit `exit 1` but SHOULD be
shut down (`SIGTERM`) by `docker-compose`.

### target

This is the simplest container, this is the container we are trying to connect
to through the tunnel.  It just needs to exist, be running, and accept logins.

#### PermitRootLogin

We do not need to be fancy and create users, but we do need to permit root to
be able to log in via SSH.

#### chpasswd

By default, on Alpine, the root account has a disabled account (this prevents
you from logging in as root EXCEPT from console, as a security measure).  SSH
will not permit ANY account to log in (even using key-based authentication) if
the account is disabled, so we set it.  The password does not matter, we never
use it.

#### ssh-keygen

Before the ssh server can start, it needs host keys.

#### touch

To signal to the `sut` service that this container is ready, we touch a file on
the shared volume; for lack of a better method.

### remote

The remote is the device we are connecting through, and requires a bit more
setup.

#### GatewayPorts

`GatewayPorts` is necessary for the `SSH_BIND_IP` variable to work properly.
Please see your ssh server documentation for details on why using is a bad
idea.

#### AllowTcpForwarding

In order for the tunnel to actually work, `AllowTcpForwarding` must be set.

### sut

The `sut` service is our **SOURCE** device in the diagram above.  This is the
last container to start as it relies on all the other containers.

#### while

These loops are just to introduce artificial delays while the other containers
boot and ready themselves.

#### ssh

Finally! All this configuration and setup comes down to a one-liner.  There is
a lot to unpack here.

In order to prove that our containers built successfully, we need to be able to
tell WHICH container we are running in at the time.  That is why every service
has a hard-coded `hostname`.

This command checks the running hostname of the server it is connecting to.  It
is designed to fail unless the hostname of container we THINK we are connecting
to actually IS the container we are connecting to.

This command succeeds only if the `ssh` command can connect to **REMOTE_PORT**
on **REMOTE** AND if the embedded command is run on **TARGET**.  All other
outcomes fail, which is what we want.

### local

This is our `autossh` container.  This is the app, this is what we are testing.
The container is built as if it was pulled from Docker Hub without the
branding variables.  This is as close to production as we can get.

Since this container never exists, and we need Docker Hub to test the exit code,
we must use another container (`sut`) to actually perform testing. This service
gets setup as if it was in production with one minor difference.

### local-with-env

Same as local, but we pass the ssh key as an environment variable.

#### SSH_KNOWN_HOSTS_FILE and SSH_STRICT_HOST_IP_CHECK

We do not want any caching or previous runs to taint the testing, so we
intentionally invalidate any `known_hosts` data and not care that we are
connecting to a "new" server.  We do not care what the fingerprints are, just
that they exist.
