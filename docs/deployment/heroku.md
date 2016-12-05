# Deploy to Heroku

## The Easy Way

If you just want to get started with Errbit and you're not sure how to proceed,
you can use this deploy button to get a basic deployment running on Heroku.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/errbit/errbit/tree/master)

After deploying the application, you still need to run `heroku run rake errbit:bootstrap` 
to create indexes and get your admin user set up.

## The Hard Way

We designed Errbit to work well with Heroku. These instructions should result
in a working deploy, but you should modify them to suit your needs:

### Clone and prepare the source code repository
```bash
git clone git@github.com:errbit/errbit.git
cd errbit
```

- Update `db/seeds.rb` with admin credentials for your initial login

Commit the results:
```bash
git commit -m "Update db/seeds.rb with initial login"
```

### Install the heroku toolbelt
[toolbelt.heroku.com](https://toolbelt.heroku.com/)

### Create an app on Heroku and push the source code
```bash
heroku apps:create
heroku addons:create mongolab:sandbox
heroku addons:create sendgrid:starter
heroku config:set GEMFILE_RUBY_VERSION=2.3.3
heroku config:set SECRET_KEY_BASE="$(bundle exec rake secret)"
heroku config:set ERRBIT_HOST=some-hostname.example.com
heroku config:set ERRBIT_EMAIL_FROM=example@example.com
heroku config:set EMAIL_DELIVERY_METHOD=smtp SMTP_SERVER=smtp.sendgrid.net
git push heroku master
```

### Prepare the DB

```bash
heroku run rake errbit:bootstrap
```

### Schedule recurring tasks
You may want to periodically clear resolved errors to free up space. For that
you have a few options:

Option 1. With the heroku-scheduler add-on (replacement for cron):

```bash
# Install the heroku scheduler add-on
heroku addons:create scheduler:standard

# Go open the dashboard to schedule the job.  You should use
# 'rake errbit:clear_resolved' as the task command, and schedule it
# at whatever frequency you like (once/day should work great).
heroku addons:create scheduler
```

Option 2. With the cron add-on:

```bash
# Install the heroku cron addon, to clear resolved errors daily:
heroku addons:create cron:daily
```

Option 3. Clear resolved errors manually:

```bash
heroku run rake errbit:clear_resolved
```
