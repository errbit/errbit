# Deploy to Dokku

Deployment to Dokku is very similiar to Heroku.
For more details see [Heroku](heroku.md) guide.

## Create an app on dokku and push the source code

```bash
dokku apps:create errbit
dokku plugin:install https://github.com/dokku/dokku-mongo.git mongo
dokku mongo:create errbit errbit
dokku mongo:link errbit errbit
# Override the automatic Dockerfile deployment detection
dokku config:set errbit BUILDPACK_URL=https://github.com/heroku/heroku-buildpack-ruby.git
dokku config:set errbit HEROKU=1
dokku config:set errbit GEMFILE_RUBY_VERSION=2.5.1
dokku config:set errbit SECRET_KEY_BASE="$(bundle exec rake secret)"
dokku config:set errbit ERRBIT_HOST=some-hostname.example.com
dokku config:set errbit ERRBIT_EMAIL_FROM=example@example.com
dokku config:set errbit EMAIL_DELIVERY_METHOD=smtp SMTP_SERVER=172.17.42.1

git remote add dokku dokku@<host>:errbit
git push dokku master
```

### Prepare the DB

```bash
dokku run errbit rake errbit:bootstrap
```
