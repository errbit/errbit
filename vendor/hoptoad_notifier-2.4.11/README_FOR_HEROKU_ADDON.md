Hoptoad
===========
Send your application errors to our hosted service and reclaim your inbox.

1. Installing the Heroku add-on
----------------------------
To use Hoptoad on Heroku, install the Hoptoad add-on:

    $ heroku addons:add hoptoad:basic # This adds the the basic plan.
                                      # If you'd like another plan, specify that instead.

2. Including the Hoptoad notifier in your application
--------------------------------------------------
After adding the Hoptoad add-on, you will need to install and configure the Hoptoad notifier.

Your application connects to Hoptoad with an API key. On Heroku, this is automatically provided to your
application in `ENV['HOPTOAD_API_KEY']`, so installation should be a snap!

### Rails 3.x

Add the hoptoad_notifier and heroku gems to your Gemfile.  In Gemfile:

    gem 'hoptoad_notifier'
    gem 'heroku'

Then from your project's RAILS_ROOT, run:

    $ bundle install
    $ script/rails generate hoptoad --heroku

### Rails 2.x

Install the heroku gem if you haven't already:

    gem install heroku

Add the hoptoad_notifier gem to your app. In config/environment.rb:

    config.gem 'hoptoad_notifier'

Then from your project's RAILS_ROOT, run:

    $ rake gems:install
    $ rake gems:unpack GEM=hoptoad_notifier
    $ script/generate hoptoad --heroku

As always, if you choose not to vendor the hoptoad_notifier gem, make sure
every server you deploy to has the gem installed or your application won't start.

### Rack applications

In order to use hoptoad_notifier in a non-Rails rack app, just load the hoptoad_notifier, configure your API key, and use the HoptoadNotifier::Rack middleware:

    require 'rubygems'
    require 'rack'
    require 'hoptoad_notifier'

    HoptoadNotifier.configure do |config|
      config.api_key = `ENV['HOPTOAD_API_KEY']`
    end

    app = Rack::Builder.app do
      use HoptoadNotifier::Rack
      run lambda { |env| raise "Rack down" }
    end

### Rails 1.x

For Rails 1.x, visit the [Hoptoad notifier's README on GitHub](http://github.com/thoughtbot/hoptoad_notifier),
and be sure to use `ENV['HOPTOAD_API_KEY']` where your API key is required in configuration code.

3. Configure your notification settings (important!)
---------------------------------------------------

Once you have included and configured the notifier in your application,
you will want to configure your notification settings.

This is important - without setting your email address, you won't receive notification emails.

Hoptoad can deliver exception notifications to your email inbox.  To configure these delivery settings:

1. Visit your application's Hoptoad Add-on page, like [ http://api.heroku.com/myapps/my-great-app/addons/hoptoad:basic ](http://api.heroku.com/myapps/my-great-app/addons/hoptoad:basic) 
2. Click "Go to Hoptoad admin" to configure the Hoptoad Add-on on the Hoptoadapp.com website
3. Click the "Profile" button in the header to edit your email address and notification settings.

4. Optionally: Set up deploy notification
-----------------------------------------

If your Hoptoad plan supports deploy notification, set it up for your Heroku application like this:

    rake hoptoad:heroku:add_deploy_notification

This will install a Heroku [HTTP Deploy Hook](http://docs.heroku.com/deploy-hooks) to notify Hoptoad of the deploy.
