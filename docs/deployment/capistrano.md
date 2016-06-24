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

# Create the configs yourself, or run errbit:setup to upload the
# defaults
bundle exec cap production errbit:setup

# Check to make sure configs exist
bundle exec cap production deploy:check

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
puma.
To start Errbit, you can run:
```bash
bundle exec cap production puma:start
```

## Status of Errbit
To check if the Errbit server is running you can run:
```bash
bundle exec cap production puma:status
```

## Stopping Errbit
To stop Errbit run

```bash
bundle exec cap production puma:stop
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
Schedule ```rake errbit:clear_resolved``` to run every day or so.


## Monit
If you like errbit to be monitored by monit, you'll have to install and start monit
with http support before deploying errbit.
In order to enable http support you have to edit the monit config file which you can
find in `/etc/monit/monitrc` for Ubuntu and set these lines:
```
set httpd port 2812 and
   use address localhost  # only accept connection from localhost
   allow localhost
```

Next you have to add the following line to the Capfile:
```
require 'capistrano/puma/monit'
```

And you have to deploy the monit config with the command:
```bash
bundle exec cap production puma:monit:config
```

The configuration file (depending on the distro) will be generated at: `/etc/monit/conf.d/puma_errbit_production.conf`

### Controlling memory usage with monit
If you like to limit memory usage for puma and restart it in case the usage gets
over a 2GB limit, for example, you can add at the end of the monit config file the line
```
if totalmem is greater than 2048 MB for 3 cycles then restart
```

The config file will look like:

```
# Monit configuration for Puma
# Service name: puma_errbit_production
#
check process puma_errbit_production
  with pidfile "/var/www/apps/errbit/shared/tmp/pids/puma.pid"
  start program = "/usr/bin/sudo -u root /bin/bash -c 'cd /var/www/apps/errbit/current && /usr/bin/env bundle exec puma -C /var/www/apps/errbit/shared/puma.rb --daemon'"
  stop program = "/usr/bin/sudo -u root /bin/bash -c 'cd /var/www/apps/errbit/current && /usr/bin/env bundle exec pumactl -S /var/www/apps/errbit/shared/tmp/pids/puma.state stop'"
  if totalmem is greater than 2048 MB for 3 cycles then restart
```
