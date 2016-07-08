---
---
# Deploy Hooks
Errbit can track your application deploys if you send a special message to
Errbit whenever you deploy.

## From heroku
If you're using heroku, you can add a deploy hook like this:
~~~bash
$ heroku addons:add deployhooks:http \
  --url=http://myerrbit.com/deploys.txt
~~~

## From the airbrake gem using the rake task
The airbrake gem comes with a nice rake task for sending deploy hooks. Assuming
you already have it configured, you can send hooks like this:
~~~bash
$ TO=env-name \
  REVISION=rev-string \
  REPO=repo-string \
  USER=user-string \
  rake airbrake:deploy
~~~

## From the airbrake gem using capistrano 3
In your application's Capfile, insert:
~~~ruby
require 'airbrake/capistrano3'
~~~

This will add a new capistrano task named ```airbrake:deploy``` which ends up
calling ```rake airbrake:deploy``` with the values from your capistrano config.
You may need to set the ```API_KEY``` environment variable on the target
application.

## From curl
Errbit supports sending a message along with your deploy hook. The airbrake gem
doesn't support this, but you can easily send it along yourself. Here's an
example using cURL:
~~~bash
$ curl https://myerrbit.com/deploys.txt \
  --data "api_key=406e4374bf508ad0d7732c2d35ed380d" \
  --data "app_id=cb71ca8429732ba86b90d57c" \
  --data "deploy[local_username]=user-string" \
  --data "deploy[rails_env]=env-name" \
  --data "deploy[scm_repository]=repo-string" \
  --data "deploy[scm_revision]=rev-string" \
  --data "deploy[message]=my-message"
~~~
