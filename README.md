= SPIRE

[SPIRE](https://github.com/spiffe/spire) (the [SPIFFE](https://github.com/spiffe/spiffe) Runtime Environment) is a tool-chain for establishing trust between software systems across a wide variety of hosting platforms. 

The configuration files included in this release are intended for evaluation
purposes only and are **NOT** production ready.

You can find additional example configurations for SPIRE [here](https://github.com/spiffe/spire-examples).

== Contents

| Path                      | Description             |
| ------------------------- | ----------------------- |
| `bin/spire-server`        | SPIRE server executable |
| `bin/spire-agent`         | SPIRE agent executable  |
| `conf/server/server.conf` | Sample SPIRE server configuration |
| `conf/agent/agent.conf`   | Sample SPIRE agent configuration |

== Configuration

The spire configuration files are installed under /var/lib/spire.
When writing the configuration file, the join token should be
specified as:

agent {
  join_token = "$join_token"
}

so it will pick the token up from the environment variable "join_token".
This environment variable is set by systemd reading
/root/spire/conf/join_token before calling spire-client.
The format of the join_token file is:
join_token=<token from spire-server>


