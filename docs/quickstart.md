# Quickstart

This is a quickstart guide to get you up and running with the Errbit.

## Prerequisites

* Linux server. We will use Debian 12.
* Docker with Docker Compose plugin
* Public IPv4 address
* (Optional) Public IPv6 address
* Domain name for Errbit. E.g. `errbit.example.com`

## Installing dependencies

* [Install Docker Engine on Debian](https://docs.docker.com/engine/install/debian/)
* [Install the Docker Compose plugin](https://docs.docker.com/compose/install/)

## Run Errbit with Docker

### Option 1: Rails native with Thruster (and without reverse proxy)

Create `docker-compose.yml` with the following content:

```yaml
services:
  errbit:
    image: "docker.io/errbit/errbit:0.11"
    container_name: "errbit"
    restart: "unless-stopped"
    environment:
      SECRET_KEY_BASE: "secret-key-base" # Replace with a secure secret key. You can generate new one with `rails secret`
      RAILS_MAX_THREADS: "2"
      ERRBIT_HOST: "errbit.example.com"
      THRUSTER_TLS_DOMAIN: "errbit.example.com"
    ports:
      - "80:80" # Listen for HTTP traffic
      - "443:443" # Listen for HTTPS traffic
    volumes:
      - "./storage:/rails/storage:rw" # Persistent SQLite database and WAL files
      - "./thruster:/rails/storage/thruster:rw" # Volume for storing ACME certificate
```

### Option 2: with Traefik as reverse proxy

Create `docker-compose.yml` with the following content:

```yaml
services:
  traefik:
    image: "docker.io/library/traefik:3.7.6"
    container_name: "traefik"
    restart: "unless-stopped"
    command:
      - "--accesslog=true"
      - "--entryPoints.web.address=:80"
      - "--entryPoints.websecure.address=:443"
      - "--providers.docker=true"
      - "--providers.docker.exposedByDefault=false"
      - "--certificatesresolvers.letsencrypt.acme.email=me@example.com" # Replace `me@example.com` with your email address
      - "--certificatesresolvers.letsencrypt.acme.storage=/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--entryPoints.web.http.redirections.entrypoint.to=websecure"
      - "--entryPoints.web.http.redirections.entrypoint.scheme=https"
    ports:
      - "80:80" # Listen for HTTP traffic
      - "443:443" # Listen for HTTPS traffic
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock" # Traefik needs access to Docker socket to discover containers
      - "./acme.json:/acme.json" # Here we store ACME certificates

  errbit:
    image: "docker.io/errbit/errbit:0.11"
    container_name: "errbit"
    restart: "unless-stopped"
    environment:
      SECRET_KEY_BASE: "secret-key-base" # Replace with a secure secret key. You can generate new one with `rails secret`
      RAILS_MAX_THREADS: "2"
      ERRBIT_HOST: "errbit.example.com" # Replace with your domain name
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.errbit.rule=Host(`errbit.example.com`)" # Replace `errbit.example.com` with your domain name
      - "traefik.http.routers.errbit.tls=true"
      - "traefik.http.routers.errbit.tls.certresolver=letsencrypt"
      - "traefik.http.routers.errbit.entrypoints=websecure"
    volumes:
      - "./storage:/rails/storage:rw" # Persistent SQLite database and WAL files
```

Create the bind-mounted storage directory before starting the container. The
image runs as UID/GID `1000`, so the directory must be writable by that user.
It stores `production.sqlite3`, its `-wal` and `-shm` sidecars, and the
Mongo-to-SQL cutover marker.

```shell
mkdir -p storage
sudo chown 1000:1000 storage
```

Run with:

```shell
docker compose pull
docker compose up -d
```

## SQLite operations

Errbit configures SQLite write-ahead logging (WAL) during bootstrap. WAL lets
readers continue while a write is in progress, but SQLite still allows only one
writer. Run a single Errbit process for small, low-write deployments; use a
server database for higher write concurrency. If you bypass bootstrap or deploy
outside Docker, run this once after `db:migrate` and before serving traffic:

```shell
bin/rails errbit:sqlite:configure
```

The `storage` mount must retain `production.sqlite3` and its `-wal` and `-shm`
sidecar files, plus `.mongo_to_sql_migrated` after a verified migration. Do not
copy the database file while Errbit is running. Create a consistent backup with
SQLite instead:

```shell
docker compose exec errbit sqlite3 /rails/storage/production.sqlite3 ".backup '/rails/storage/production-backup.sqlite3'"
```

Stop with:

```shell
docker compose down
```

If you are updating Errbit:

```shell
docker compose down
docker compose pull
docker compose up -d
```
