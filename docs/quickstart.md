# Quickstart

This is a quickstart guide to get you up and running with the Errbit.

## Prerequisites

* Linux server. We will use Debian 12.
* Docker with Docker Compose plugin
* Public IPv4 address
* (Optional) public IPv6 address
* Domain name for errbit. E.g. `errbit.example.com`

## Installing dependencies

* [Install Docker Engine on Debian](https://docs.docker.com/engine/install/debian/)
* [Install the Docker Compose plugin](https://docs.docker.com/compose/install/)

## Run Errbit with Docker

### Option 1: with Traefik

```shell
# mkdir errbit
# cd errbit
# touch docker-compose.yml
```

Fill `docker-compose.yml` with the following content:

```yaml
services:
  traefik:
    image: "docker.io/library/traefik:3.3.5"
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
      - "80:80" # HTTP
      - "443:443" # HTTPS
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "./acme.json:/acme.json"

  errbit:
    image: "docker.io/errbit/errbit:latest"
    container_name: "errbit"
    restart: "unless-stopped"
    environment:
      MONGO_URL: "mongodb://host:27017/errbit_production" # Replace with URL to your MongoDB instance
      SECRET_KEY_BASE: "secret-key-base" # Replace with a secure secret key. You can generate new one with `rails secret`
      RAILS_MAX_THREADS: "2"
      ERRBIT_HOST: "errbit.example.com"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.errbit.rule=Host(`errbit.example.com`)" # Replace `errbit.example.com` with your domain name
      - "traefik.http.routers.errbit.tls=true"
      - "traefik.http.routers.errbit.tls.certresolver=letsencrypt"
      - "traefik.http.routers.errbit.entrypoints=websecure"
```

Run with:

```shell
docker compose pull
docker compose up -d
```

Stop with:

```shell
docker compose down
```

If you are updating Errbit

```shell
docker compose down
docker compose pull
docker compose up -d
```

### Option 2: Rails native with Thruster

