# Deployment Notes
There are any number of ways to deploy Errbit, but official support is limited
to heroku and capistrano.

See specific notes on deployment via:
- [heroku](deployment/heroku.md)
- [dokku](deployment/dokku.md)
- [capistrano](deployment/capistrano.md)
- [docker](deployment/docker.md)
- [kubernetes (experimental)](deployment/kubernetes.md)

You can use a process manager to deploy Errbit, but Errbit doesn't maintain
support for any specific process manager. But if you use systemd, @nofxx has
been kind enough to share:
- [systemd config](https://gist.github.com/nofxx/f01dcfe3e9d504181d76)

## HTTPS

Errbit can be deployed with HTTPS in a couple different ways.

Nginx or Apache can be used as a reverse-proxy to Errbit's Puma.
In this scenario, Nginx or Apache is configured to serve using HTTPS.
The user sends an HTTPS request to Nginx or Apache.
Nginx or Apache decrypts the request and passes it on to Errbit using plain
HTTP.

Alternatively, Errbit's Puma can be configured to serve HTTPS directly.
Instead of starting Errbit with the command:
```bash
bundle exec puma -C config/puma.default.rb
```
start it with:
```bash
bundle exec puma -b "ssl://0.0.0.0:443?key=server.key&cert=server.crt" -C config/puma.default.rb
```
Where `server.key` is a path to the TLS private key and `server.crt` is the path
to the TLS certificate.
