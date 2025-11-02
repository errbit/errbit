# Deploy with Docker

Errbit provides official [Docker](https://www.docker.com/) images to
make Docker deployment easy. You can pass all of [Errbit's
configuration](/docs/configuration.md) to the Docker container using
`docker run -e`.

When running Errbit using `docker run` you must specify a `MONGO_URL`. If
you're running in a production environment, you should also specify
`RAILS_ENV=production` and `SECRET_KEY_BASE=some-secret-key`.

If you don't already have one, you can generate a suitable `SECRET_KEY_BASE`
with:

```shell
docker run --rm errbit/errbit bundle exec rake secret
```

## Which image version should I use?

We are again releasing non-latest tags to Docker Hub. Please see
[errbit/errbit](https://hub.docker.com/r/errbit/errbit/tags), which is
updated on main builds and stable releases.

## Standalone Errbit App

Assuming you have a Mongo host available, you can run Errbit using `docker
run`, exposing its HTTP interface on port 3000:

```bash
docker run \
  -e "RAILS_ENV=production" \
  -e "MONGO_URL=mongodb://my-mongo-host" \
  -e "SECRET_KEY_BASE=my$ecre7key123" \
  -p 3000:3000 \
  errbit/errbit:latest
```

Now run `bundle exec rake errbit:bootstrap` to bootstrap the Errbit db within an ephemeral
Docker container:

```shell
docker run \
  --rm \
  -e "RAILS_ENV=production" \
  -e "MONGO_URL=mongodb://my-mongo-host" \
  errbit/errbit:latest \
  bundle exec rake errbit:bootstrap
```

## Errbit + Dependencies via Docker Compose

Docker compose can take care of starting up a Mongo container along with the
Errbit application container and linking the two containers together:

```shell
docker-compose up -e "SECRET_KEY_BASE=my$ecre7key123"
```

Now run `bundle exec rake errbit:bootstrap` to bootstrap the Errbit db within an ephemeral
Docker container:

```shell
docker exec errbit_errbit_1 bundle exec rake errbit:bootstrap
```
