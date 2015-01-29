# Deploy with Docker
Errbit provides official [docker](https://www.docker.com/) images to
make docker deployment easy.  You can pass all of [Errbit's
configuration](docs/configuration.md) to the Docker container using
`docker run -e`.

For instance, if you already have a mongo, pass along the mongo URL
using `docker run -e "MONGO_URL=mongodb://my-mongo-url". This example
will run an Errbit process in the background, giving it the name
'my-errbit':
```bash
docker run -d \
  -e "MONGO_URL=mongodb://my-mongo-url" \
  --name my-errbit \
  -p 5000:5000 \
  stevecrozz/errbit
```

If you want to run mongo in a container as well, you can use `--link` to
link your Errbit and mongo containers:

```bash
docker run -d \
  --name my-mongo \
  mongo

docker run -d \
  --link my-mongo:my-mongo
  -e "MONGO_URL=mongodb://my-mongo/mydbname" \
  --name my-errbit \
  -p 5000:5000 \
  stevecrozz/errbit
```

Errbit should now be accessible on your Docker host over port 5000.
