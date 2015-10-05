# Errbit [![TravisCI][travis-img-url]][travis-ci-url] [![Code Climate][codeclimate-img-url]][codeclimate-url] [![Coveralls][coveralls-img-url]][coveralls-url] [![Dependency Status][gemnasium-img-url]][gemnasium-url] [![Deploy](https://www.herokucdn.com/deploy/button.svg)][heroku-deploy-url]

[travis-img-url]: https://travis-ci.org/errbit/errbit.svg?branch=master
[travis-ci-url]: http://travis-ci.org/errbit/errbit
[codeclimate-img-url]: https://codeclimate.com/github/errbit/errbit.png
[codeclimate-url]: https://codeclimate.com/github/errbit/errbit
[coveralls-img-url]: https://coveralls.io/repos/errbit/errbit/badge.png?branch=master
[coveralls-url]:https://coveralls.io/r/errbit/errbit
[gemnasium-img-url]:https://gemnasium.com/errbit/errbit.png
[gemnasium-url]:https://gemnasium.com/errbit/errbit
[heroku-deploy-url]:https://heroku.com/deploy?template=https://github.com/errbit/errbit/tree/master

### The open source, self-hosted error catcher

Errbit is a tool for collecting and managing errors from other applications.
It is [Airbrake](http://airbrake.io) API compliant, so if you are already using
Airbrake, you can just point the `airbrake` gem to your Errbit server.

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

Mailing List
------------

Join the Google Group at https://groups.google.com/group/errbit to receive
updates and notifications.

# Requirements

The list of requirements to install Errbit are:

* Ruby 2.1.0 or higher
* MongoDB 2.6.0 or higher

Installation
------------

*Note*: This app is intended for people with experience deploying and maintaining
Rails applications. If you're uncomfortable with any steps below then Errbit is not
for you.

* [Install MongoDB](https://www.mongodb.org/downloads)
* git clone https://github.com/errbit/errbit.git
* bundle install
* bundle exec rake errbit:bootstrap
* bundle exec rails server

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

Notice Grouping
---------------
The way Errbit arranges notices into error groups is configurable. By default,
Errbit uses the notice's error class, error message, complete backtrace,
component (or controller), action and environment name to generate a unique
fingerprint for every notice. Notices with identical fingerprints appear in the
UI as different occurences of the same error and notices with differing
fingerprints are displayed as separate errors.

Changing the fingerprinter (under the 'config' menu) applies to all apps and
the change affects only notices that arrive after the change. If you want to
refingerprint old notices, you can run `rake errbit:notice_refingerprint`.

Authentication
--------------
### Configuring GitHub authentication:
* Set GITHUB_AUTHENTICATION=true
* Register your instance of Errbit at https://github.com/settings/applications

If you host Errbit at errbit.example.com, you would fill in:

<dl>
<dt>URL
<dd>http://errbit.example.com
<dt>Callback URL
<dd>http://errbit.example.com/users/auth/github
</dl>

* After you have registered your app, set GITHUB_CLIENT_ID and GITHUB_SECRET
  with your app's Client ID and Secret key.

When you start your applicatoin, you should see the option to **Sign in with
GitHub** on the Login page. You will also be able to link your GitHub profile
to your user account on your **Edit profile** page.

If you have signed in with GitHub, or linked your GitHub profile, and you're
working with an App that has a GitHub repo configured, then you will be able to
create issues on GitHub. If you use another issue tracker, see [Issue
Trackers](#issue-trackers).

You can change the OAuth scope Errbit requests from GitHub by setting
`GITHUB_ACCESS_SCOPE`. The default ['repo'] is very permissive, but there are a
few others that could make sense for your needs:

<dl>
<dt>GITHUB_ACCESS_SCOPE="['repo']"</dt>
<dd>Allow creating issues for public and private repos</dd>
<dt>GITHUB_ACCESS_SCOPE="['public_repo']"</dt>
<dd>Allow creating issues for public repos only</dd>
<dt>GITHUB_ACCESS_SCOPE="[]"</dt>
<dd>No permissions at all, but allows errbit login through github</dd>
</dl>

* GITHUB_ORG_ID is an optional environment variable you can set to your own
  github organization id. If set, only users of the specified GitHub
  organization can log in to Errbit through GitHub. Errbit will provision
  accounts for new users.

### Configuring LDAP authentication:

* Set USER_HAS_USERNAME=true
* Follow the instructions at
  https://github.com/cschiewek/devise_ldap_authenticatable to set up the
  devise_ldap_authenticatable gem.
* Set ```config.ldap_create_user = true``` in ```config/initializers/devise.rb```, this enables creating the users from LDAP, otherwhise login will not work.
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
rake db:mongoid:create_indexes
rake db:mongoid:remove_undefined_indexes
rake assets:precompile
```

This will ensure that your application stays up to date with any schema changes.

### Upgrading errbit beyond v0.4.0

* You must have already run migrations at least up to v0.3.0. Check to
  make sure you're schema version is at least 20131011155638 by running rake
  db:version before you upgrade beyond v0.4.0

### Upgrading errbit from v0.3.0 to v0.4.0

* All configuration is now done through the environment. See
  [configuration](docs/configuration.md)
* Ruby 1.9 and 2.0 are no longer offically supported. Please upgrade to Ruby
  2.1+
* Errbit now maintains an issue tracker only for github. If you're using
  another issue tracker integration, you may need to maintain it yourself. See
  [Issue Trackers](#issue-trackers)

## User information in error reports

Errbit can now display information about the user who experienced an error.
This gives you the ability to ask the user for more information,
and let them know when you've fixed the bug.

The Airbrake gem will look for ```current_user``` or ```current_member```. By defailt it will only send the ```id``` of the user, to specify other attributes you can set ```config.user_attributes```. See [the Airbrake wiki for more information](https://github.com/airbrake/airbrake/wiki/Sending-current-user-information).

If user information is received with an error report,
it will be displayed under the *User Details* tab:

![User details tab](http://errbit.github.com/errbit/images/error_user_information.png)

This tab will be hidden if no user information is available.

Javascript error notifications
--------------------------------------

You can log javascript errors that occur in your application by including the
[airbrake-js](https://github.com/airbrake/airbrake-js) javascript library.

Install airbrake-js according to the docs at
[airbrake-js](https://github.com/airbrake/airbrake-js) and set your project and
host as early as possible:

```javascript
Airbrake.setProject("ERRBIT API KEY", "ERRBIT API KEY");
Airbrake.setHost("http://errbit.yourdomain.com");
```

Plugins and Integrations
------------------------
You can extend Errbit by adding Ruby gems and plugins which are typically gems.
It's nice to keep track of which gems are core Errbit dependencies and which
gems are your own dependencies. If you want to add gems to your own Errbit,
place them in a new file called `UserGemfile` and Errbit will treat that file
as an additional Gemfile. If you want to use a file with a different name, you
can pass the name of that file in an environment variable named `USER_GEMFILE`.
If you want to use errbit_jira_plugin, just add it to UserGemfile:

```bash
echo "gem 'errbit_jira_plugin'" > UserGemfile
bundle install
```

Issue Trackers
--------------
Each issue tracker integration is implemented as a gem that depends on
[errbit_plugin](https://github.com/errbit/errbit_plugin). The only officially
supported issue tracker plugin is
[errbit_github_plugin](https://github.com/errbit/errbit_github_plugin).

If you want to implement your own issue tracker plugin, read the README.md file
at [errbit_plugin](https://github.com/errbit/errbit_plugin).

What if Errbit has an error?
----------------------------

Errbit will log it's own errors to an internal app named **Self.Errbit**.  The
**Self.Errbit** app is automatically created when the first error happens.

If your Errbit instance has logged an error, we would appreciate a bug report
on GitHub Issues. You can post this manually at
[https://github.com/errbit/errbit/issues](https://github.com/errbit/errbit/issues),
or you can set up the GitHub Issues tracker for your **Self.Errbit** app:

  * Go to the **Self.Errbit** app's edit page. If that app does not exist yet,
    go to the apps page and click **Add a new App** to create it. (You can also
    create it by running `rake airbrake:test`.)
  * In the **Issue Tracker** section, click **GitHub Issues**.
  * Fill in the **Account/Repository** field with **errbit/errbit**.
  * Fill in the **Username** field with your github username.
  * If you are logged in on [GitHub](https://github.com), you can find your
    **API Token** on this page:
    [https://github.com/account/admin](https://github.com/account/admin).
  * Save the settings by clicking **Update App** (or **Add App**)
  * You can now easily post bug reports to GitHub Issues by clicking the
    **Create Issue** button on a **Self.Errbit** error.

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

People using Errbit
-------------------

See our wiki page for a [list of people and companies around the world who use
Errbit](https://github.com/errbit/errbit/wiki/People-using-Errbit). You may
[edit this
page](https://github.com/errbit/errbit/wiki/People-using-Errbit/_edit), and add
your name and country to the list if you are using Errbit.


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

See the [contributors graph](https://github.com/errbit/errbit/graphs/contributors) for more details.

Contributing to Errbit
------------

See the [contribution guidelines](CONTRIBUTING.md)

Running tests
-------------

Check the .travis.yml file to see how tests are run

Copyright
---------

Copyright (c) 2010-2015 Errbit Team
