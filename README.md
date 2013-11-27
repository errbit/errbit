# Errbit [![TravisCI][travis-img-url]][travis-ci-url] [![Code Climate][codeclimate-img-url]][codeclimate-url] [![Coveralls][coveralls-img-url]][coveralls-url] [![Dependency Status][gemnasium-img-url]][gemnasium-url]

[travis-img-url]: https://secure.travis-ci.org/errbit/errbit.png?branch=master
[travis-ci-url]: http://travis-ci.org/errbit/errbit
[codeclimate-img-url]: https://codeclimate.com/github/errbit/errbit.png
[codeclimate-url]: https://codeclimate.com/github/errbit/errbit
[coveralls-img-url]: https://coveralls.io/repos/errbit/errbit/badge.png?branch=master
[coveralls-url]:https://coveralls.io/r/errbit/errbit
[gemnasium-img-url]:https://gemnasium.com/errbit/errbit.png
[gemnasium-url]:https://gemnasium.com/errbit/errbit



### The open source, self-hosted error catcher


Errbit is a tool for collecting and managing errors from other applications.
It is [Airbrake](http://airbrake.io) (formerly known as Hoptoad) API compliant,
so if you are already using Airbrake, you can just point the `airbrake` gem to your Errbit server.


<table>
  <tr>
    <td align="center">
      <a href="http://errbit.github.com/errbit/images/apps.png" target="_blank" title="Apps">
        <img src="http://errbit.github.com/errbit/images/apps_thumb.png" alt="Apps">
      </a>
      <br />
      <em>Apps</em>
    </td>
    <td align="center">
      <a href="http://errbit.github.com/errbit/images/app_errors.png" target="_blank" title="Errors">
        <img src="http://errbit.github.com/errbit/images/app_errors_thumb.png" alt="Errors">
      </a>
      <br />
      <em>Errors</em>
    </td>
    <td align="center">
      <a href="http://errbit.github.com/errbit/images/error_summary.png" target="_blank" title="Error Summary">
        <img src="http://errbit.github.com/errbit/images/error_summary_thumb.png" alt="Error Summary">
      </a>
      <br />
      <em>Error Summary</em>
    </td>
    <td align="center">
      <a href="http://errbit.github.com/errbit/images/error_backtrace.png" target="_blank" title="Error Backtraces">
        <img src="http://errbit.github.com/errbit/images/error_backtrace_thumb.png" alt="Error Backtraces">
      </a>
      <br />
      <em>Error Backtraces</em>
    </td>
  </tr>
</table>


Errbit may be a good fit for you if:

* Your exceptions may contain sensitive data that you don't want sitting on someone else's server
* Your application is behind a firewall
* You'd like to brand your error catcher
* You want to add customer features to your error catcher
* You're crazy and love managing servers

If this doesn't sound like you, you should probably stick with a hosted service such as
[Airbrake](http://airbrake.io).


Mailing List
------------

Join the Google Group at https://groups.google.com/group/errbit to receive updates and notifications.

Demo
----

There is a demo available at [http://errbit-demo.herokuapp.com/](http://errbit-demo.herokuapp.com/)

Email: demo@errbit-demo.herokuapp.com<br/>
Password: password

# Requirement

The list of requirement to install Errbit is :

 * Ruby 1.9.3 or higher
 * MongoDB 2.2.0 or higher

By default it's the Ruby 2.0.0 to use. But you can define your own ruby
version with RUBY_VERSION variable between :

 * 1.9.3
 * 2.0.0
 * 2.1.0

Installation
------------

*Note*: This app is intended for people with experience deploying and maintaining
Rails applications. If you're uncomfortable with any step below then Errbit is not
for you.

**Set up your local box or server(Ubuntu):**

  * Install MongoDB. Follow the directions [here](http://www.mongodb.org/display/DOCS/Ubuntu+and+Debian+packages), then:

```bash
apt-get update
apt-get install mongodb-10gen
```

  * Install libxml and libcurl

```bash
apt-get install libxml2 libxml2-dev libxslt-dev libcurl4-openssl-dev
```

  * Install Bundler

```bash
gem install bundler
```

**Running Locally:**

  * Install dependencies

```bash
bundle install
```

  * Bootstrap Errbit. This will copy over config.yml and also seed the database.

```bash
rake errbit:bootstrap
```

  * Update the config.yml and mongoid.yml files with information about your environment

  * Start Server

```bash
script/rails server
```

Deploying:
----------

  * Copy `config/deploy.example.rb` to `config/deploy.rb`
  * Update the `deploy.rb` or `config.yml` file with information about your server
  * Setup server and deploy

```bash
cap deploy:setup deploy db:create_mongoid_indexes
```

(Note: The capistrano deploy script will automatically generate a unique secret token.)

**Deploying to Heroku:**

  * Clone the repository

```bash
git clone http://github.com/errbit/errbit.git
```
  * Update `db/seeds.rb` with admin credentials for your initial login.

  * Run `bundle`

  * Create & configure for Heroku

```bash
gem install heroku
heroku create example-errbit
# If you really want, you can define your stack and your buildpack. the default is good to us :
# heroku create example-errbit --stack cedar --buildpack https://github.com/heroku/heroku-buildpack-ruby.git
heroku addons:add mongolab:sandbox
heroku addons:add sendgrid:starter
heroku config:add HEROKU=true
heroku config:add SECRET_TOKEN="$(bundle exec rake secret)"
heroku config:add ERRBIT_HOST=some-hostname.example.com
heroku config:add ERRBIT_EMAIL_FROM=example@example.com
# This next line is required to access env variables during asset compilation.
# For more info, go to this link: https://devcenter.heroku.com/articles/labs-user-env-compile
heroku labs:enable user-env-compile
git push heroku master
```

  * Seed the DB (_NOTE_: No bootstrap task is used on Heroku!) and
    create index

```bash
heroku run rake db:seed
heroku run rake db:mongoid:create_indexes
```

  * If you are using a free database on Heroku, you may want to periodically clear resolved errors to free up space.

    * With the heroku-scheduler add-on (replacement for cron):

    ```bash
    # Install the heroku scheduler add-on
    heroku addons:add scheduler:standard

    # Go open the dashboard to schedule the job.  You should use
    # 'rake errbit:db:clear_resolved' as the task command, and schedule it
    # at whatever frequency you like (once/day should work great).
    heroku addons:open scheduler
    ```

    * With the cron add-on:

    ```bash
    # Install the heroku cron addon, to clear resolved errors daily:
    heroku addons:add cron:daily
    ```

    * Or clear resolved errors manually:

    ```bash
    heroku run rake errbit:db:clear_resolved
    ```

  * You may want to enable the deployment hook for heroku :

```bash
heroku addons:add deployhooks:http --url="http://YOUR_ERRBIT_HOST/deploys.txt?api_key=YOUR_API_KEY"
```

  * You may also want to configure a different secret token for each deploy:

```bash
heroku config:add SECRET_TOKEN=some-secret-token
```

  * Enjoy!


Authentication
--------------

### Configuring GitHub authentication:

  * In `config/config.yml`, set `github_authentication` to `true`
  * Register your instance of Errbit at: https://github.com/settings/applications

If you hosted Errbit at errbit.example.com, you would fill in:

<table>
  <tr><th>URL:</th><td>http://errbit.example.com/</td></tr>
  <tr><th>Callback URL:</th><td>http://errbit.example.com/users/auth/github</td></tr>
</table>

  * After you have registered your app, set `github_client_id` and `github_secret`
    in `config/config.yml` with your app's Client ID and Secret key.


After you have followed these instructions, you will be able to **Sign in with GitHub** on the Login page.

You will also be able to link your GitHub profile to your user account on your **Edit profile** page.

If you have signed in with GitHub, or linked your GitHub profile, and the App has a GitHub repo configured,
then you will be able to create issues on GitHub.
You will still be able to create an issue on the App's configured issue tracker.

You can change the requested account permissions by setting `github_access_scope` to:

<table>
  <tr><th>['repo'] </th><td>Allow creating issues for public and private repos.</td></tr>
  <tr><th>['public_repo'] </th><td>Only allow creating issues for public repos.</td></tr>
  <tr><th>[] </th><td>No permission to create issues on any repos.</td></tr>
</table>


### GitHub authentication when served on Heroku

You will need to set up Heroku variables accordingly as described in [Configuring GitHub authentication](#configuring-github-authentication):

* GITHUB_AUTHENTICATION

```bash
heroku config:add GITHUB_AUTHENTICATION=true
```

* GITHUB_CLIENT_ID

```bash
heroku config:add GITHUB_CLIENT_ID=the_client_id_provided_by_GitHub
```

* GITHUB_SECRET

```bash
heroku config:add GITHUB_SECRET=the_secret_provided_by_GitHub
```

* GITHUB_ACCESS_SCOPE - set only one scope `repo` or `public_repo`. If you really need to put more than one, separate them with comma.

```bash
heroku config:add GITHUB_ACCESS_SCOPE=repo,public_repo
```

__Note__: To avoid restarting your Heroku app 4 times you can set Heroku variables in a single command, i.e:

```bash
heroku config:add GITHUB_AUTHENTICATION=true \
GITHUB_CLIENT_ID=the_client_id_provided_by_GitHub \
GITHUB_SECRET=the_secret_provided_by_GitHub \
GITHUB_ACCESS_SCOPE=repo,public_repo
```

### Configuring LDAP authentication:

  * In `config/config.yml`, set `user_has_username` to `true`
  * Follow the instructions at https://github.com/cschiewek/devise_ldap_authenticatable
  to set up the devise_ldap_authenticatable gem.
  * Ensure to set ```config.ldap_create_user = true``` in ```config/initializers/devise.rb```, this enables creating the users from LDAP, otherwhise login will not work.
  * Create a new initializer (e.g. ```config/initializers/devise_ldap.rb```) and add the following code to enable ldap authentication in the User-model:
```ruby
Errbit::Config.devise_modules << :ldap_authenticatable
```

  * If you are authenticating by `username`, you will need to set the user's email manually
  before authentication. You must add the following lines to `app/models/user.rb`:

```ruby
  def ldap_before_save
    name = Devise::LDAP::Adapter.get_ldap_param(self.username, "givenName")
    surname = Devise::LDAP::Adapter.get_ldap_param(self.username, "sn")
    mail = Devise::LDAP::Adapter.get_ldap_param(self.username, "mail")

    self.name = (name + surname).join ' '
    self.email = mail.first
  end
```

  * Now login with your user from LDAP, this will create a user in the database
  * Open a rails console and set the admin flag for your user:

```ruby
user = User.first
user.admin = true
user.save!
```

## Upgrading

When upgrading Errbit, please run:

```bash
git pull origin master # assuming origin is the github.com/errbit/errbit repo
bundle install
rake db:migrate
rake assets:precompile
```

If we change the way that data is stored, this will run any migrations to bring your database up to date.


### Upgrade from errbit 0.2 to 0.3

The file of MongoDB connection config/mongoid.yml change between 0.2 to
0.3. So Check the new config/mongoid.yml.example file and update it in
good way.

This change is not need to be done if you use only ENV variable to
define you access to MongoDB database.


## User information in error reports

Errbit can now display information about the user who experienced an error.
This gives you the ability to ask the user for more information,
and let them know when you've fixed the bug.

If you would like to include information about the current user in your error reports,
you can replace the `airbrake` gem in your Gemfile with `airbrake_user_attributes`,
which wraps the `airbrake` gem and injects user information.
It will inject information about the current user into the error report
if your Rails app's controller responds to a `#current_user` method.
The user's attributes are filtered to remove authentication fields.

If user information is received with an error report,
it will be displayed under the *User Details* tab:


![User details tab](http://errbit.github.com/errbit/images/error_user_information.png)

(This tab will be hidden if no user information is available.)

Adding javascript errors notifications
--------------------------------------

Errbit easily supports javascript errors notifications. You just need to add `config.js_notifier = true` to the errbit initializer in the rails app.

```
Errbit.configure do |config|
  config.host    = 'YOUR-ERRBIT-HOST'
  config.api_key = 'YOUR-PROJECT-API-KEY'
  config.js_notifier = true
end
```

Then get the `notifier.js` from `errbit/public/javascript/notifier.js` and add to `application.js` on your rails app or include `http://YOUR-ERRBIT-HOST/javascripts/notifier.js` on your `application.html.erb.`

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
* Card properties are comma separated key value pairs. You must specify a 'card_type', but anything else is optional, e.g.:

```
card_type = Defect, status = Open, priority = Essential
```

**GitHub Issues Integration**

* For 'Account/Repository', the account will either be a username or organization. i.e. **errbit/errbit**
* You will also need to provide your username and password for your GitHub account.
  * (We'd really appreciate it if you wanted to help us implement OAuth instead!)

**Bitbucket Issues Integration**

* For 'BITBUCKET REPO' field, the account will either be a username or organization. i.e. **errbit/errbit**
* You will also need to provide your username and password for your Bitbucket account.

**Gitlab Issues Integration**

* Account is the host of your gitlab installation. i.e. **http://gitlab.example.com**
* To authenticate, Errbit uses token-based authentication. Get your API Key in your user settings (or create special user for this purpose)
* You also need to provide project ID (it needs to be Number) for issues to be created

**Unfuddle Issues Integration**

* Account is your unfuddle domain
* Username your unfuddle username
* Password your unfuddle password
* Project id the id of your project where your ticket is create
* Milestone id the id of your milestone where your ticket is create

**Jira Issue Integration**

* base_url the jira URL
* context_path Context Path (Just "/" if empty otherwise with leading slash)
* username HTTP Basic Auth User
* password HTTP Basic Auth Password
* project_id The project Key where the issue will be created
* account Assign to this user. If empty, Jira takes the project default.
* issue_component Website - Other
* issue_type Issue type
* issue_priority Priority

Notification Service
--------------------

**Flowdock Notification**

Allow notification to [Flowdock](https://www.flowdock.com/). See
[complete documentation](docs/notifications/flowdock/index.md)


What if Errbit has an error?
----------------------------

Errbit will log it's own errors to an internal app named **Self.Errbit**.
The **Self.Errbit** app will be automatically created whenever the first error happens.

If your Errbit instance has logged an error, we would appreciate a bug report on GitHub Issues.
You can post this manually at [https://github.com/errbit/errbit/issues](https://github.com/errbit/errbit/issues),
or you can set up the GitHub Issues tracker for your **Self.Errbit** app:

  * Go to the **Self.Errbit** app's edit page. If that app does not exist yet, go to the apps page and click **Add a new App** to create it. (You can also create it by running `rake airbrake:test`.)

  * In the **Issue Tracker** section, click **GitHub Issues**.

  * Fill in the **Account/Repository** field with **errbit/errbit**.

  * Fill in the **Username** field with your github username.

  * If you are logged in on [GitHub](https://github.com), you can find your **API Token** on this page: [https://github.com/account/admin](https://github.com/account/admin).

  * Save the settings by clicking **Update App** (or **Add App**)

  * You can now easily post bug reports to GitHub Issues by clicking the **Create Issue** button on a **Self.Errbit** error.


Use Errbit with applications written in other languages
-------------------------------------------------------

In theory, any Airbrake-compatible error catcher for other languages should work with Errbit.
Solutions known to work are listed below:

<table>
  <tr>
    <th>PHP (&gt;= 5.3)</th>
    <td>https://github.com/flippa/errbit-php</td>
  </tr>
  <tr>
    <th>OOP PHP (&gt;= 5.3)</th>
    <td>https://github.com/emgiezet/errbitPHP</td>
  </tr>
  <tr>
    <th>Python</th>
    <td>https://github.com/mkorenkov/errbit.py , https://github.com/pulseenergy/airbrakepy</td>
  </tr>
</table>

Develop on Errbit
-----------------

A guide can help on this way on  [**Errbit Advanced Developer Guide**](docs/DEVELOPER-ADVANCED.md)

## Other documentation

* [All ENV variables availables to configure Errbit](docs/ENV-VARIABLES.md)

TODO
----

* Add ability for watchers to be configured for types of notifications they should receive


People using Errbit
-------------------

See our wiki page for a [list of people and companies around the world who use Errbit](https://github.com/errbit/errbit/wiki/People-using-Errbit).
Feel free to [edit this page](https://github.com/errbit/errbit/wiki/People-using-Errbit/_edit), and add your name and country to the list if you are using Errbit.


Special Thanks
--------------

* [Michael Parenteau](http://michaelparenteau.com) - For rocking the Errbit design and providing a great user experience.
* [Nick Recobra (@oruen)](https://github.com/oruen) - Nick is Errbit's first core contributor. He's been working hard at making Errbit more awesome.
* [Nathan Broadbent (@ndbroadbent)](https://github.com/ndbroadbent) - Maintaining Errbit and contributing many features
* [Vasiliy Ermolovich (@nashby)](https://github.com/nashby) - Contributing and helping to resolve issues and pull requests
* [Marcin Ciunelis (@martinciu)](https://github.com/martinciu) - Helping to improve Errbit's architecture
* [Cyril Mougel (@shingara)](https://github.com/shingara) - Maintaining Errbit and contributing many features
* [Relevance](http://thinkrelevance.com) - For giving me Open-source Fridays to work on Errbit and all my awesome co-workers for giving feedback and inspiration.
* [Thoughtbot](http://thoughtbot.com) - For being great open-source advocates and setting the bar with [Airbrake](http://airbrake.io).

See the [contributors graph](https://github.com/errbit/errbit/graphs/contributors) for further details. You can see another list of Contributors by release version on [CONTRIBUTORS.md]


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
* Add you on the CONTRIBUTORS.md file on the current release


Copyright
---------

Copyright (c) 2010-2013 Errbit Team. See LICENSE for details.



[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/errbit/errbit/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

