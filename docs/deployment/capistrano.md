# Deploy with Capistrano
These instructions should be good enough to get you started deploying
capistrano with Errbit. More than likely, you'll have to adjust some things to
suit your needs, so you should understand how to use capistrano before you
continue.

## Clone and prepare the source code repository
```bash
git clone git@github.com:errbit/errbit.git
cd errbit
```

- Copy `config/deploy.example.rb` to `config/deploy.rb`
- Update the `deploy.rb` or `config.yml` file with information about your server
- Setup server and deploy

## Schedule recurring tasks
You may want to periodically clear resolved errors to free up space. Schedule
the ```rake errbit:db:clear_resolved``` rake task to run every day or so.
