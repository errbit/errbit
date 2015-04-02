# Deploy with Capistrano
These instructions should be good enough to get you started deploying
capistrano with Errbit. More than likely, you'll have to adjust some
things to suit your needs, so you should understand how to use
capistrano before you continue.

## Clone and prepare the source code repository

```bash
git clone git@github.com:errbit/errbit.git
cd errbit

# Create and edit deploy.rb
cp config/deploy.example.rb config/deploy.rb
$EDITOR config/deploy.rb

# Create and edit production.rb
cp config/deploy/production.example.rb config/deploy/production.rb
$EDITOR config/deploy/production.rb

# Check to make sure configs exist
bundle exec cap production deploy:check

# Create the configs yourself, or run errbit:setup to upload the
# defaults
bundle exec cap production errbit:setup

# Deploy
bundle exec cap production deploy

# Setup the remote DB if you haven't already
bundle exec cap production db:setup
```

## Static Assets
For a deployment of any real size, you'll probably want to set up a web
server for efficiently serving static assets. If you choose to go this
route, just map all requests for /assets/.\* to
/deploy/path/shared/public/assets

## Starting Errbit
Errbit comes with some capistrano tasks to manage running Errbit under
unicorn.
To start Errbit, you can run:
```bash
bundle exec cap production unicorn:start
```

Supervising and monitoring Errbit is beyond the scope of this
documentation.


### rbenv support

Pass `rbenv` environment when running `cap` to use rbenv. See
[capistrano/rbenv](https://github.com/capistrano/rbenv) for more
information.

```bash
rbenv=1 bundle exec cap production deploy
```

## Schedule recurring tasks
You may want to periodically clear resolved errors to free up space.
Schedule ```rake errbit:db:clear_resolved``` to run every day or so.
