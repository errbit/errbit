# Deployment Notes

There are any number of ways to deploy Errbit, but official support is limited
to Heroku.

See specific notes on deployment via:

* [Heroku](deployment/heroku.md)
* [Dokku](deployment/dokku.md)
* [Docker](deployment/docker.md)
* [Kubernetes (experimental)](deployment/kubernetes.md)

## HTTPS

Errbit can be deployed with HTTPS in a couple different ways.

Nginx or Apache can be used as a reverse-proxy to Errbit's Puma.
In this scenario, Nginx or Apache is configured to serve using HTTPS.
The user sends an HTTPS request to Nginx or Apache.
Nginx or Apache decrypts the request and passes it on to Errbit using plain
HTTP.

Alternatively, Errbit's Puma can be configured to serve HTTPS directly.
Instead of starting Errbit with the command:

```shell
bundle exec puma -C config/puma.rb
```

start it with:

```shell
bundle exec puma -b "ssl://0.0.0.0:443?key=server.key&cert=server.crt" -C config/puma.rb
```

Where `server.key` is a path to the TLS private key and `server.crt` is the path
to the TLS certificate.

## Health Checks

If deploying with a system that can check if the app is running as expected then
there are two endpoints that can be used:

* `/health/readiness` - suitable for checking if app is ready to receive
  requests. If response status is 200 and body contains `{ "ok": true,
"details": [etc...] }` then the app is ready.

* `/health/liveness` - suitable for pinging periodically to check if app is still
  alive. Expected result is `{ "ok": true }`.
