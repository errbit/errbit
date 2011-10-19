Errbit [![TravisCI](https://travis-ci.org/errbit/errbit.png?branch=master)](http://travis-ci.org/errbit/errbit)
======

**The open source self-hosted error catcher**

Errbit is a tool for collecting and managing errors from other applications.
It is [Airbrake](http://airbrakeapp.com) (formerly known as Hoptoad) API compliant,
so if you are already using Airbrake, you can just point hoptoad_notifier at your Errbit server.

Errbit may be a good fit for you if:

* Your exceptions may contain sensitive data that you don't want sitting on someone else's server
* Your application is behind a firewall
* You'd like to brand your error catcher
* You want to add customer features to your error catcher
* You're crazy and love managing servers

If this doesn't sound like you, you should probably stick with [Airbrake](http://airbrakeapp.com).
The [Thoughtbot](http://thoughtbot.com) guys offer great support for it and it is much more worry-free.
They have a free package and even offer a *"Airbrake behind your firewall"* solution.

Demo
----

There is a demo available at [http://errbit-demo.herokuapp.com/](http://errbit-demo.herokuapp.com/)

Email: demo@errbit-demo.herokuapp.com
Password: password

Installation
------------

*Note*: This app is intended for people with experience deploying and maintining
Rails applications. If you're uncomfortable with any step below then Errbit is not
for you. Checkout [Airbrake](http://airbrakeapp.com) from the guys over at
[Thoughtbot](http://thoughtbot.com), which Errbit is based on.

**Set up your local box or server(Ubuntu):**

  1. Install MongoDB. Follow the directions [here](http://www.mongodb.org/display/DOCS/Ubuntu+and+Debian+packages), then:

```bash
apt-get update
apt-get install mongodb
```

  2. Install libxml and libcurl

```bash
apt-get install libxml2 libxml2-dev libxslt-dev libcurl4-openssl-dev
```

  3. Install Bundler

```bash
gem install bundler
```

**Running Locally:**

  1. Install dependencies

```bash
bundle install
```

  2. Bootstrap Errbit. This will copy over config.yml and also seed the database.

```bash
rake errbit:bootstrap
```

  3. Update the config.yml and mongoid.yml files with information about your environment

  4. Start Server

```bash
script/rails server
```

**Deploying:**

  1. Bootstrap Errbit. This will copy over config.yml and also seed the database.

```bash
rake errbit:bootstrap
```

  2. Update the deploy.rb file with information about your server
  3. Setup server and deploy

```bash
cap deploy:setup deploy
```

**Deploying to Heroku:**

  1. Clone the repository

```bash
git clone http://github.com/errbit/errbit.git
```

  2. Create & configure for Heroku

```bash
gem install heroku
heroku create example-errbit --stack cedar
heroku addons:add mongohq:free
heroku addons:add sendgrid:starter
heroku config:add HEROKU=true
heroku config:add ERRBIT_HOST=some-hostname.example.com
heroku config:add ERRBIT_EMAIL_FROM=example@example.com
git push heroku master
```

  3. Seed the DB (_NOTE_: No bootstrap task is used on Heroku!)

```bash
heroku run rake db:seed
```

  4. If you are using a free database on Heroku, you may want to periodically clear resolved errors to free up space.

```bash
# Install the heroku cron addon, to clear resolved errors daily:
heroku addons:add cron:daily

# Or, clear resolved errors manually:
heroku rake errbit:db:clear_resolved
```

  5. Enjoy!


**Configuring LDAP authentication:**

  1. In `config/config.yml`, set `user_has_username` to `true`
  2. Follow the instructions at https://github.com/cschiewek/devise_ldap_authenticatable
  to set up the devise_ldap_authenticatable gem.

  3. If you are authenticating by `username`, you will need to set the user's email
  after authentication. You can do this by adding the following lines to `app/models/user.rb`:

```ruby
  before_save :set_ldap_email
  def set_ldap_email
    self.email = Devise::LdapAdapter.get_ldap_param(self.username, "mail")
  end
```

Upgrading
---------
*Note*: When upgrading Errbit, please run:

```bash
git pull origin master # assuming origin is the github.com/errbit/errbit repo
rake db:migrate
```

If we change the way that data is stored, this will run any migrations to bring your database up to date.


Issue Trackers
--------------

**Lighthouseapp Integration**

* Account is the name of your subdomain, i.e. **litcafe** for project at http://litcafe.lighthouseapp.com/projects/73466-face/overview
* Errbit uses token-based authentication. Get your API Token or visit [http://help.lighthouseapp.com/kb/api/how-do-i-get-an-api-token](http://help.lighthouseapp.com/kb/api/how-do-i-get-an-api-token) to learn how to get it.
* Project id is number identifier of your project, i.e. **73466** for project at http://litcafe.lighthouseapp.com/projects/73466-face/overview

**Redmine Integration**

* Account is the host of your redmine installation, i.e. **http://redmine.org**
* Errbit uses token-based authentication. Get your API Key or visit [http://www.redmine.org/projects/redmine/wiki/Rest_api#Authentication](http://www.redmine.org/projects/redmine/wiki/Rest_api#Authentication) to learn how to get it.
* Project id is an identifier of your project, i.e. **chilliproject** for project at http://www.redmine.org/projects/chilliproject

**Pivotal Tracker Integration**

* Errbit uses token-based authentication. Get your API Key or visit [http://www.pivotaltracker.com/help/api](http://www.pivotaltracker.com/help/api) to learn how to get it.
* Project id is an identifier of your project, i.e. **24324** for project at http://www.pivotaltracker.com/projects/24324

**Thoughtworks Mingle Integration**

* Account is the host of your mingle installation. i.e. **https://mingle.example.com**  *note*: You should use SSL if possible.
* Errbit uses 'sign-in name' & password authentication. You may want to set up an **errbit** user with limited rights.
* Project id is the identifier of your project, i.e. **awesomeapp** for project at https://mingle.example.com/projects/awesomeapp
* Card properties are comma separated key value pairs. You must specify a 'card_type', but anything else is optional. i.e. card_type = Defect, status = Open, priority = Essential

**Github Issues Integration**

* For 'Account/Repository', the account will either be a username or organization. i.e. **errbit/errbit**
* If you are logged in on [Github](https://github.com), you can find your **API Token** on this page: [https://github.com/account/admin](https://github.com/account/admin).
* You will also need to provide the username that your API Token is connected to.


What if Errbit has an error?
----------------------------

Errbit will log it's own errors to an internal app named **Self.Errbit**.
The **Self.Errbit** app will be automatically created whenever the first error happens.

If your Errbit instance has logged an error, we would appreciate a bug report on Github Issues.
You can post this manually at [https://github.com/errbit/errbit/issues](https://github.com/errbit/errbit/issues),
or you can set up the Github Issues tracker for your **Self.Errbit** app:

  1. Go to the **Self.Errbit** app's edit page. If that app does not exist yet, go to the apps page and click **Add a new App** to create it. (You can also create it by running `rake hoptoad:test`.)

  2. In the **Issue Tracker** section, click **Github Issues**.

  3. Fill in the **Account/Repository** field with **errbit/errbit**.

  4. Fill in the **Username** field with your github username.

  5. If you are logged in on [Github](https://github.com), you can find your **API Token** on this page: [https://github.com/account/admin](https://github.com/account/admin).

  6. Save the settings by clicking **Update App** (or **Add App**)

  7. You can now easily post bug reports to Github Issues by clicking the **Create Issue** button on a **Self.Errbit** error.


TODO
----

* Add ability for watchers to be configured for types of notifications they should receive


Special Thanks
--------------

* [Michael Parenteau](http://michaelparenteau.com) - For rocking the Errbit design and providing a great user experience.
* [Nick Recobra aka oruen](https://github.com/oruen) - Nick is Errbit's first core contributor. He's been working hard at making Errbit more awesome.
* [Relevance](http://thinkrelevance.com) - For giving me Open-source Fridays to work on Errbit and all my awesome co-workers for giving feedback and inspiration.
* [Thoughtbot](http://thoughtbot.com) - For being great open-source advocates and setting the bar with [Airbrake](http://airbrakeapp.com).


Contributing
------------

We welcome any contributions. If you need to tweak Errbit for your organization's needs,
there are probably other users who will appreciate your work.
Please try to determine whether or not your feature should be **global** or **optional**,
and make **optional** features configurable via `config/config.yml`.

**Examples of optional features:**

* Enable / disable user comments on errors.
* Adding a `username` field to the User model.

**How to contribute:**

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so we don't break it in a future version unintentionally.
* Commit, do not mess with Rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself we can ignore when we pull)
* Send us a pull request. Bonus points for topic branches.


Copyright
---------

Copyright (c) 2010-2011 Jared Pace. See LICENSE for details.

