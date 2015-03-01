# Deploy to Heroku
We designed Errbit to work well with Heroku. These instructions should result
in a working deploy, but you should modify them to suit your needs:

## Clone and prepare the source code repository
```bash
git clone git@github.com:errbit/errbit.git
cd errbit
```

- Update `db/seeds.rb` with admin credentials for your initial login

Commit the results:
```bash
git commit -m "Update db/seeds.rb with initial login"
```

## Install the heroku toolbelt
[toolbelt.heroku.com](https://toolbelt.heroku.com/)

## Create an app on Heroku and push the source code
```bash
heroku apps:create
heroku addons:add mongolab:sandbox
heroku addons:add sendgrid:starter
heroku config:add GEMFILE_RUBY_VERSION=2.2.0
heroku config:add SECRET_KEY_BASE="$(bundle exec rake secret)"
heroku config:add ERRBIT_HOST=some-hostname.example.com
heroku config:add ERRBIT_EMAIL_FROM=example@example.com
git push heroku master
```

## Prepare the DB

```bash
heroku run rake errbit:bootstrap
```

## Schedule recurring tasks
You may want to periodically clear resolved errors to free up space. For that
you have a few options:

Option 1. With the heroku-scheduler add-on (replacement for cron):

```bash
# Install the heroku scheduler add-on
heroku addons:add scheduler:standard

# Go open the dashboard to schedule the job.  You should use
# 'rake errbit:db:clear_resolved' as the task command, and schedule it
# at whatever frequency you like (once/day should work great).
heroku addons:open scheduler
```

Option 2. With the cron add-on:

```bash
# Install the heroku cron addon, to clear resolved errors daily:
heroku addons:add cron:daily
```

Option 3. Clear resolved errors manually:

```bash
heroku run rake errbit:db:clear_resolved
```

## Add the deployment hook
```bash
heroku addons:add deployhooks:http --url="http://YOUR_ERRBIT_HOST/deploys.txt?api_key=YOUR_API_KEY"
```
