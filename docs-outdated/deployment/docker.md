# Deploy with Docker

Errbit provides official [Docker](https://www.docker.com/) images to
make Docker deployment easy. You can pass all of [Errbit's
configuration](/docs/configuration.md) to the Docker container using
`docker run -e`.

When running Errbit using `docker run` you must specify a MONGO_URL. If you're
running in a production environment, you should also specify
RACK_ENV=production and SECRET_KEY_BASE=some-secret-key.

If you don't already have one, you can generate a suitable SECRET_KEY_BASE
with:
```bash
docker run --rm errbit/errbit bundle exec rake secret
```

## Which image version should I use?

As of 2023, we are not releasing non-latest tags to docker hub (last release was v0.9.0 in 2020).
Please use [errbit/errbit:latest](https://hub.docker.com/r/errbit/errbit/tags), which is updated on main builds.
If you are interested in using official release tags of errbit, contributions to the CI process and shipping stable releases would be welcome.

## Standalone Errbit App

Assuming you have a mongo host available, you can run errbit using `docker
run`, exposing its HTTP interface on port 8080:
```bash
docker run \
  -e "RACK_ENV=production" \
  -e "MONGO_URL=mongodb://my-mongo-host" \
  -e "SECRET_KEY_BASE=my$ecre7key123" \
  -p 8080:8080 \
  errbit/errbit:latest
```

Now run `bundle exec rake errbit:bootstrap` to bootstrap the Errbit db within an ephemeral
Docker container:

```bash
docker run \
  --rm \
  -e "RACK_ENV=production" \
  -e "MONGO_URL=mongodb://my-mongo-host" \
  errbit/errbit:latest \
  bundle exec rake errbit:bootstrap
```

## Errbit + Dependencies via Docker Compose

Docker compose can take care of starting up a mongo container along with the
Errbit application container and linking the two containers together:

```bash
docker-compose up -e "SECRET_KEY_BASE=my$ecre7key123"
```

Now run `bundle exec rake errbit:bootstrap` to bootstrap the Errbit db within an ephemeral
Docker container:

```bash
docker exec errbit_errbit_1 bundle exec rake errbit:bootstrap
```
