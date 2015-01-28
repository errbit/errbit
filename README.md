# Errbit [![TravisCI][travis-img-url]][travis-ci-url] [![Code Climate][codeclimate-img-url]][codeclimate-url] [![Coveralls][coveralls-img-url]][coveralls-url] [![Dependency Status][gemnasium-img-url]][gemnasium-url]

[travis-img-url]: https://travis-ci.org/errbit/errbit.svg?branch=master
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

# Requirements

The list of requirements to install Errbit are :

 * Ruby 2.1.0 or higher
 * MongoDB 2.2.0 or higher

Installation
------------

*Note*: This app is intended for people with experience deploying and maintaining
Rails applications. If you're uncomfortable with any steps below then Errbit is not
for you.

**Set up your local box or server(Ubuntu):**

  * Install MongoDB. Follow the directions [here](http://www.mongodb.org/display/DOCS/Ubuntu+and+Debian+packages), then:

```bash
apt-get update
apt-get install mongodb-10gen
```

  * Install libxml, libzip, libssl and libcurl

```bash
apt-get install libxml2 libxml2-dev libxslt-dev libcurl4-openssl-dev libzip-dev libssl-dev
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

  * Bootstrap Errbit. This will seed the database.

```bash
rake errbit:bootstrap
```

  * Start Server

```bash
script/rails server
```

Configuration
-------------
Errbit configuration is done entirely through environment variables. See
[configuration](docs/configuration.md)

Deploy Hooks
-------------
Errbit can track your application deploys. See [deploy hooks](docs/deploy-hooks.md)

Deployment
----------
See [notes on deployment](docs/deployment.md)

Authentication
--------------
### Configuring GitHub authentication:
* Set GITHUB_AUTHENTICATION to true
* Register your instance of Errbit at https://github.com/settings/applications

If you hosted Errbit at errbit.example.com, you would fill in:

<table>
  <tr><th>URL:</th><td><a href="http://errbit.example.com/">http://errbit.example.com/</a></td></tr>
  <tr><th>Callback URL:</th><td><a href="http://errbit.example.com/users/auth/github">http://errbit.example.com/users/auth/github</a></td></tr>
</table>

* After you have registered your app, set GITHUB_CLIENT_ID and GITHUB_SECRET
  with your app's Client ID and Secret key.

When you start your applicatoin, you should see the option to **Sign in with
GitHub** on the Login page.

You will also be able to link your GitHub profile to your user account on your
**Edit profile** page.

If you have signed in with GitHub, or linked your GitHub profile, and the App
has a GitHub repo configured, then you will be able to create issues on GitHub.
You will still be able to create an issue on the App's configured issue
tracker.

You can change the requested account permissions by setting
`GITHUB_ACCESS_SCOPE` to:

<table>
  <tr><th>['repo'] </th><td>Allow creating issues for public and private repos.</td></tr>
  <tr><th>['public_repo'] </th><td>Only allow creating issues for public repos.</td></tr>
  <tr><th>[] </th><td>No permission to create issues on any repos.</td></tr>
</table>

* GITHUB_ORG_ID is an optional environment variable you can set to your own
  github organization id. If set, any user of the specified GitHub organization
  can login.  If it is their first time, an account will automatically be
  created for them.

### Configuring LDAP authentication:

  * Set `USER_HAS_USERNAME` to `true`
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

This will ensure that your application stays up to date with any schema changes.


### Upgrading errbit from version 0.2 to 0.3

The MongoDB connection file `config/mongoid.yml` has changed between version 0.2 and
0.3. We have provided a new example configuration file to use at `config/mongoid.example.yml`.

This change is not needed if you use ENV variables to
define access to your MongoDB database.


## User information in error reports

Errbit can now display information about the user who experienced an error.
This gives you the ability to ask the user for more information,
and let them know when you've fixed the bug.

If you are running a Rails application and would like to include information
about the current user in your error reports, you can replace the `airbrake`
gem in your Gemfile with `airbrake_user_attributes`.
This gem is a wrapper around the `airbrake` gem and will automatically
inject information about the user into any error reports,
so long as your controllers respond to a `#current_user` method.
The user's attributes are filtered to remove authentication fields.

If user information is received with an error report,
it will be displayed under the *User Details* tab:


![User details tab](http://errbit.github.com/errbit/images/error_user_information.png)

(This tab will be hidden if no user information is available.)

Javascript error notifications
--------------------------------------

You can log javascript errors that occur in your application by including
[airbrake-js](https://github.com/airbrake/airbrake-js) javascript library.

First you need to add airbrake-shim.js to your site and set some basic configuration
options:

```
<script src="airbrake-shim.js" data-airbrake-project-id="ERRBIT API KEY" data-airbrake-project-key="ERRBIT API KEY" data-airbrake-environment-name="production" data-airbrake-host="http://errbit.yourdomain.com"></script>
```

Or you can just add shim file and set these options using:

```
Airbrake.setProject("ERRBIT API KEY", "ERRBIT API KEY");
Airbrake.setHost("http://errbit.yourdomain.com");
```

And that's it.

Testing API V3 using ruby airbrake client
-----------------------------------------

If you want you test standard airbrake ruby gem with API V3. To do that you
need to change your airbrake initializer file to something like this:

```
Airbrake.configure do |config|
  config.api_key = ENV['airbrake_api_key']
  config.host    = ENV['airbrake_host']
  config.port    = ENV['airbrake_port'].to_i
  config.secure  = ENV['airbrake_secure'] == 'true'
  config.project_id = ENV['airbrake_api_key']
end

class Airbrake::Sender
  def json_api_enabled?
    true
  end
end
```

It is important to set project_id option to the same value as api_key, because
project_id is required for building url to api endpoint. And airbrake has a bug
that removes api_key from endpoint url. The only way to get this value is by passing
it as project_id. This little monkey-patch is required because airbrake gem only
uses v3 api when host is set to collect.airbrake.io.

V3 request don't have framework option so you won't see this value in your error
notices in errbit. Besides that everything looks the same. It was tested using
rake airbrake:test for both v2 and v3.

Using custom fingerprinting methods
-----------------------------------

Errbit allows you to use your own Fingerprinting Strategy.
If you are upgrading from a very old version of errbit, you can use the `Fingerprint::MD5` for compatibility. The fingerprint strategy can be changed by adding an initializer to errbit:

```ruby
# config/fingerprint.rb
ErrorReport.fingerprint_strategy = Fingerprint::MD5
```

The easiest way to add custom fingerprint methods is to simply subclass `Fingerprint`

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
    <td>[flippa/errbit-php](https://github.com/flippa/errbit-php)</td>
  </tr>
  <tr>
    <th>OOP PHP (&gt;= 5.3)</th>
    <td>[emgiezet/errbitPHP](https://github.com/emgiezet/errbitPHP)</td>
  </tr>
  <tr>
    <th>Python</th>
    <td>[mkorenkov/errbit.py](https://github.com/mkorenkov/errbit.py) , [pulseenergy/airbrakepy](https://github.com/pulseenergy/airbrakepy)</td>
  </tr>
</table>

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


Contributing to Errbit
------------

We welcome any contributions. If you need to tweak Errbit for your organization's needs,
there are probably other users who will appreciate your work.
Please try to determine whether or not your feature should be **global** or **optional**,
and make **optional** features configurable via environment variables.

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

# Running tests

More information can be found in the  [**Errbit Advanced Developer Guide**](docs/DEVELOPER-ADVANCED.md)


Copyright
---------

Copyright (c) 2010-2014 Errbit Team. See LICENSE for details.

