# Deploy with Capistrano
These instructions should be good enough to get you started deploying
capistrano with Errbit. More than likely, you'll have to adjust some things to
suit your needs, so you should understand how to use capistrano before you
continue.

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

# Create required directories.
# It will print out what files are missing.
# Create them manually or use errbit:setup_configs task after first deploy
bundle exec cap production deploy:check
```

### rbenv support

Pass `rbenv` environment when running `cap` to use rbenv.

```bash
rbenv=1 bundle exec cap production deploy
```

## Schedule recurring tasks
You may want to periodically clear resolved errors to free up space. Schedule
the ```rake errbit:db:clear_resolved``` rake task to run every day or so.
