# Docker Compose Stack

The compose example under `dockerfiles/compose/` is a lab-style deployment that
brings up Asterisk, MariaDB, PHP-FPM, RTPengine, and Kamailio.

## Location

- Compose file: [`dockerfiles/compose/docker-compose.yml`](../dockerfiles/compose/docker-compose.yml)
- Runtime data directory: `dockerfiles/compose/runtime/`

## Services

- `asterisk`: prebuilt Asterisk Certified image
- `mariadb`: database container with init SQL mounted from the repo
- `php-fpm`: web/PHP helper container
- `rtpengine`: media proxy built from the local Dockerfile
- `kamailio`: SIP proxy built from the local Dockerfile

## Characteristics

- Uses `network_mode: host`
- Stores runtime state in a local `runtime/` directory
- Includes example passwords and image references
- Targets experimentation and operator customization, not a hardened default

## Running It

```bash
cd dockerfiles/compose
./up.sh
```

Stop or tear down with:

```bash
./stop.sh
./down.sh
```

## Before Using Beyond a Lab

- Replace example passwords and secrets
- Review mounted configuration and file ownership
- Confirm host-networking implications for your environment
- Validate SIP, RTP, and database exposure rules
- Pin image versions intentionally
