Errbit: The open source self-hosted error catcher
=================================================

Errbit is an open source, self-hosted error catcher. It is [Hoptoad](http://hoptoadapp.com)
API compliant so you can just point the Hoptoad notifier at your Errbit server if you are
already using Hoptoad.

Errbit may be a good fit for you if:

* Your exceptions may contain sensitive data that you don't want sitting on someone else's server
* Your application is behind a firewall
* You'd like to brand your error catcher
* You want to add customer features to your error catcher
* You're crazy and love managing servers

If this doesn't sound like you, you should probably stick with [Hoptoad](http://hoptoadapp.com).
The [Thoughtbot](http://thoughtbot.com) guys offer great support for it and it is much more worry-free.
They have a free package and even offer a *"Hoptoad behind your firewall"* solution.

Installation
------------

*Note*: This app is intended for people with experience deploying and maintining
Rails applications. If you're uncomfortable with any step below then Errbit is not
for you. Checkout [Hoptoad](http://hoptoadapp.com) from the guys over at
[Thoughtbot](http://thoughtbot.com), which Errbit is based on.

**Set your local box or server(Ubuntu):**

  1. Install MongoDB. Follow the directions [here](http://www.mongodb.org/display/DOCS/Ubuntu+and+Debian+packages), then:

         aptitude update
         aptitude install mongodb

  2. Install libxml

         apt-get install libxml2 libxml2-dev libxslt-dev

  3. Install Bundler

         gem install bundler

**Running Locally:**

  1. Bootstrap Errbit. This will copy over config.yml and also seed the database.

         rake errbit:bootstrap

  2. Update the config.yml and mongoid.yml files with information about your environment
  3. Install dependencies

         bundle install

  4. Start Server

         script/rails server

**Deploying:**

  1. Bootstrap Errbit. This will copy over config.yml and also seed the database.

         rake errbit:bootstrap

  2. Update the deploy.rb file with information about your server
  3. Setup server and deploy

         cap deploy:setup deploy

**Deploying to Heroku:**

  1. Clone the repository

         git clone http://github.com/jdpace/errbit.git

  2. Create & configure for Heroku

         gem install heroku
         heroku create
         heroku addons:add mongohq:free
         heroku addons:add sendgrid:free
         heroku config:add HEROKU=true
         heroku config:add ERRBIT_HOST=some-hostname.example.com
         heroku config:add ERRBIT_EMAIL_FROM=example@example.com
         git push heroku master

  3. Seed the DB (_NOTE_: No bootstrap task is used on Heroku!)

         heroku rake db:seed

  4. Enjoy!

Upgrading
---------
*Note*: If upgrading from a version of Errbit that used Notices embedded in Errs please run:

         1. git pull origin master ( assuming origin is the github.com/jdpace/errbit repo )
         2. rake db:migrate

Lighthouseapp integration
-------------------------

* Account is the name of your subdomain, i.e. **litcafe** for project at http://litcafe.lighthouseapp.com/projects/73466-face/overview
* Errbit uses token-based authentication. Get your API Token or visit [http://help.lighthouseapp.com/kb/api/how-do-i-get-an-api-token](http://help.lighthouseapp.com/kb/api/how-do-i-get-an-api-token) to learn how to get it.
* Project id is number identifier of your project, i.e. **73466** for project at http://litcafe.lighthouseapp.com/projects/73466-face/overview

Redmine integration
-------------------------

* Account is the host of your redmine installation, i.e. **http://redmine.org**
* Errbit uses token-based authentication. Get your API Key or visit [http://www.redmine.org/projects/redmine/wiki/Rest_api#Authentication](http://www.redmine.org/projects/redmine/wiki/Rest_api#Authentication) to learn how to get it.
* Project id is an identifier of your project, i.e. **chilliproject** for project at http://www.redmine.org/projects/chilliproject

Pivotal Tracker integration
-------------------------

* Errbit uses token-based authentication. Get your API Key or visit [http://www.pivotaltracker.com/help/api](http://www.pivotaltracker.com/help/api) to learn how to get it.
* Project id is an identifier of your project, i.e. **24324** for project at http://www.pivotaltracker.com/projects/24324

TODO
----

* Add ability for watchers to be configured for types of notifications they should receive

Special Thanks
--------------

* [Michael Parenteau](http://michaelparenteau.com) - For rocking the Errbit design and providing a great user experience.
* [Nick Recobra aka oruen](https://github.com/oruen) - Nick is Errbit's first core contributor. He's been working hard at making Errbit more awesome.
* [Relevance](http://thinkrelevance.com) - For giving me Open-source Fridays to work on Errbit and all my awesome co-workers for giving feedback and inspiration.
* [Thoughtbot](http://thoughtbot.com) - For being great open-source advocates and setting the bar with [Hoptoad](http://hoptoadapp.com).

Contributing
------------

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with Rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Copyright
---------

Copyright (c) 2010 Jared Pace. See LICENSE for details.
