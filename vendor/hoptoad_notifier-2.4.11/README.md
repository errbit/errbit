HoptoadNotifier
===============

This is the notifier gem for integrating apps with Hoptoad.

When an uncaught exception occurs, HoptoadNotifier will POST the relevant data
to the Hoptoad server specified in your environment.

Help
----

For help with using Hoptoad and the Hoptoad notifier visit [our support site](http://help.hoptoadapp.com)

For discussion of Hoptoad notifier development check out the [mailing list](http://groups.google.com/group/hoptoad-notifier-dev)

Rails Installation
------------------

### Remove exception_notifier

in your ApplicationController, REMOVE this line:

    include ExceptionNotifiable

In your config/environment* files, remove all references to ExceptionNotifier

Remove the vendor/plugins/exception_notifier directory.

### Remove hoptoad_notifier plugin

Remove the vendor/plugins/hoptoad_notifier directory before installing the gem, or run:

    script/plugin remove hoptoad_notifier

### Rails 3.x

Add the hoptoad_notifier gem to your Gemfile.  In Gemfile:

    gem "hoptoad_notifier", "~> 2.3"

Then from your project's RAILS_ROOT, run:

    bundle install
    script/rails generate hoptoad --api-key your_key_here

That's it!

### Rails 2.x

Add the hoptoad_notifier gem to your app. In config/environment.rb:

    config.gem 'hoptoad_notifier'

Then from your project's RAILS_ROOT, run:

    rake gems:install
    rake gems:unpack GEM=hoptoad_notifier
    script/generate hoptoad --api-key your_key_here

As always, if you choose not to vendor the hoptoad_notifier gem, make sure
every server you deploy to has the gem installed or your application won't start.

### Rails 1.2.6

Install the hoptoad_notifier gem:

    gem install hoptoad_notifier

Once installed, you should vendor the hoptoad_notifier gem:

    mkdir vendor/gems
    cd vendor/gems
    gem unpack hoptoad_notifier

And then add the following to the Rails::Initializer.run do |config|
block in environment.rb so that the vendored gem is loaded.

    # Add the vendor/gems/*/lib directories to the LOAD_PATH
    config.load_paths += Dir.glob(File.join(RAILS_ROOT, 'vendor', 'gems', '*', 'lib'))

Next add something like this at the bottom of your config/environment.rb:

    require 'hoptoad_notifier'
    require 'hoptoad_notifier/rails'
    HoptoadNotifier.configure do |config|
      config.api_key = 'your_key_here'
    end

You will also need to copy the hoptoad_notifier_tasks.rake file into your
RAILS_ROOT/lib/tasks directory in order for the rake hoptoad:test task to work:

    cp vendor/gems/hoptoad_notifier-*/generators/hoptoad/templates/hoptoad_notifier_tasks.rake lib/tasks

As always, if you choose not to vendor the hoptoad_notifier gem, make sure
every server you deploy to has the gem installed or your application won't start.

### Upgrading From Earlier Versions of Hoptoad

If you're currently using the plugin version (if you have a
vendor/plugins/hoptoad_notifier directory, you are), you'll need to perform a
few extra steps when upgrading to the gem version.

Add the hoptoad_notifier gem to your app. In config/environment.rb:

    config.gem 'hoptoad_notifier'

Remove the plugin:

    rm -rf vendor/plugins/hoptoad_notifier

Make sure the following line DOES NOT appear in your ApplicationController file:

    include HoptoadNotifier::Catcher

If it does, remove it.  The new catcher is automatically included by the gem
version of Hoptoad.

Before running the hoptoad generator, you need to find your project's API key.
Log in to your account at hoptoadapp.com, and click on the "Projects" button.
Then, find your project in the list, and click on its name. In the left-hand
column, you'll see an "Edit this project" button. Click on that to get your
project's API. (If you accidentally use your personal API auth_token, you won't
be able to install the gem.)

Then from your project's RAILS_ROOT, run:

    rake gems:install
    script/generate hoptoad --api-key your_key_here

Once installed, you should vendor the hoptoad_notifier gem.

    rake gems:unpack GEM=hoptoad_notifier

As always, if you choose not to vendor the hoptoad_notifier gem, make sure
every server you deploy to has the gem installed or your application won't
start.

### Upgrading from Earlier Versions of the Hoptoad Gem (with config.gem)

If you're currently using the gem version of the hoptoad_notifier and have
a version of Rails that uses config.gem (in the 2.x series), there is
a step or two that you need to do to upgrade. First, you need to remove
the old version of the gem from vendor/gems:

    rm -rf vendor/gems/hoptoad_notifier-X.X.X

Then you must remove the hoptoad_notifier_tasks.rake file from lib:

    rm lib/tasks/hoptoad_notifier_tasks.rake

You can them continue to install normally. If you don't remove the rake file,
you will be unable to unpack this gem (Rails will think it's part of the
framework).

### Testing it out

You can test that Hoptoad is working in your production environment by using
this rake task (from RAILS_ROOT):

    rake hoptoad:test

If everything is configured properly, that task will send a notice to Hoptoad
which will be visible immediately.

Rack
----

In order to use hoptoad_notifier in a non-Rails rack app, just load the
hoptoad_notifier, configure your API key, and use the HoptoadNotifier::Rack
middleware:

    require 'rack'
    require 'hoptoad_notifier'

    HoptoadNotifier.configure do |config|
      config.api_key = 'my_api_key'
    end

    app = Rack::Builder.app do
      use HoptoadNotifier::Rack
      run lambda { |env| raise "Rack down" }
    end

Sinatra
-------

Using hoptoad_notifier in a Sinatra app is just like a Rack app, but you have
to disable Sinatra's error rescuing functionality:

    require 'sinatra/base'
    require 'hoptoad_notifier'
  
    HoptoadNotifier.configure do |config|
      config.api_key = 'my_api_key'
    end
  
    class MyApp < Sinatra::Default
      use HoptoadNotifier::Rack
      enable :raise_errors
  
      get "/" do
        raise "Sinatra has left the building"
      end
    end

Usage
-----

For the most part, Hoptoad works for itself.  Once you've included the notifier
in your ApplicationController (which is now done automatically by the gem),
all errors will be rescued by the #rescue_action_in_public provided by the gem.

If you want to log arbitrary things which you've rescued yourself from a
controller, you can do something like this:

    ...
    rescue => ex
      notify_hoptoad(ex)
      flash[:failure] = 'Encryptions could not be rerouted, try again.'
    end
    ...

The #notify_hoptoad call will send the notice over to Hoptoad for later
analysis. While in your controllers you use the notify_hoptoad method, anywhere
else in your code, use HoptoadNotifier.notify.

To perform custom error processing after Hoptoad has been notified, define the
instance method #rescue_action_in_public_without_hoptoad(exception) in your
controller.

Informing the User
------------------

The Notifier gem is capable of telling the user information about the error that just happened
via the user_information option. They can give this error number in bug resports, for example.
By default, if your 500.html contains the text

    <!-- HOPTOAD ERROR -->

then that comment will be replaced with the text "Hoptoad Error [errnum]". You can modify the text
of the informer by setting config.user_information. The Notifier will replace "{{ error_id }}" with the
ID of the error that is returned from Hoptoad.

  HoptoadNotifier.configure do |config|
    ...
    config.user_information = "<p>Tell the devs that it was <strong>{{ error_id }}</strong>'s fault.</p>"
  end

You can also turn the middleware completely off by setting config.user_information to false.

Tracking deployments in Hoptoad
-------------------------------

Paying Hoptoad plans support the ability to track deployments of your application in Hoptoad.
By notifying Hoptoad of your application deployments, all errors are resolved when a deploy occurs,
so that you'll be notified again about any errors that reoccur after a deployment.

Additionally, it's possible to review the errors in Hoptoad that occurred before and after a deploy.

When Hoptoad is installed as a gem, you need to add

    require 'hoptoad_notifier/capistrano'

to your deploy.rb

If you don't use Capistrano, then you can use the following rake task from your
deployment process to notify Hoptoad:

    rake hoptoad:deploy TO=#{rails_env} REVISION=#{current_revision} REPO=#{repository} USER=#{local_user}

Going beyond exceptions
-----------------------

You can also pass a hash to notify_hoptoad method and store whatever you want,
not just an exception. And you can also use it anywhere, not just in
controllers:

    begin
      params = {
        # params that you pass to a method that can throw an exception
      }
      my_unpredicable_method(params)
    rescue => e
      HoptoadNotifier.notify(
        :error_class   => "Special Error",
        :error_message => "Special Error: #{e.message}",
        :parameters    => params
      )
    end

While in your controllers you use the notify_hoptoad method, anywhere else in
your code, use HoptoadNotifier.notify. Hoptoad will get all the information
about the error itself. As for a hash, these are the keys you should pass:

* :error_class - Use this to group similar errors together. When Hoptoad catches an exception it sends the class name of that exception object.
* :error_message - This is the title of the error you see in the errors list. For exceptions it is "#{exception.class.name}: #{exception.message}"
* :parameters - While there are several ways to send additional data to Hoptoad, passing a Hash as :parameters as in the example above is the most common use case. When Hoptoad catches an exception in a controller, the actual HTTP client request parameters are sent using this key.

Hoptoad merges the hash you pass with these default options:

    {
      :api_key       => HoptoadNotifier.api_key,
      :error_message => 'Notification',
      :backtrace     => caller,
      :parameters    => {},
      :session       => {}
    }

You can override any of those parameters.

### Sending shell environment variables when "Going beyond exceptions"

One common request we see is to send shell environment variables along with
manual exception notification.  We recommend sending them along with CGI data
or Rack environment (:cgi_data or :rack_env keys, respectively.)

See HoptoadNotifier::Notice#initialize in lib/hoptoad_notifier/notice.rb for
more details.

Filtering
---------

You can specify a whitelist of errors, that Hoptoad will not report on.  Use
this feature when you are so apathetic to certain errors that you don't want
them even logged.

This filter will only be applied to automatic notifications, not manual
notifications (when #notify is called directly).

Hoptoad ignores the following exceptions by default:

    AbstractController::ActionNotFound
    ActiveRecord::RecordNotFound
    ActionController::RoutingError
    ActionController::InvalidAuthenticityToken
    ActionController::UnknownAction
    CGI::Session::CookieStore::TamperedWithCookie

To ignore errors in addition to those, specify their names in your Hoptoad
configuration block.

    HoptoadNotifier.configure do |config|
      config.api_key      = '1234567890abcdef'
      config.ignore       << "ActiveRecord::IgnoreThisError"
    end

To ignore *only* certain errors (and override the defaults), use the
#ignore_only attribute.

    HoptoadNotifier.configure do |config|
      config.api_key      = '1234567890abcdef'
      config.ignore_only  = ["ActiveRecord::IgnoreThisError"]
    end

To ignore certain user agents, add in the #ignore_user_agent attribute as a
string or regexp:

    HoptoadNotifier.configure do |config|
      config.api_key      = '1234567890abcdef'
      config.ignore_user_agent  << /Ignored/
      config.ignore_user_agent << 'IgnoredUserAgent'
    end

To ignore exceptions based on other conditions, use #ignore_by_filter:

    HoptoadNotifier.configure do |config|
      config.api_key      = '1234567890abcdef'
      config.ignore_by_filter do |exception_data|
        true if exception_data[:error_class] == "RuntimeError"
      end
    end

To replace sensitive information sent to the Hoptoad service with [FILTERED] use #params_filters:

    HoptoadNotifier.configure do |config|
      config.api_key      = '1234567890abcdef'
      config.params_filters << "credit_card_number"
    end

Note that, when rescuing exceptions within an ActionController method,
hoptoad_notifier will reuse filters specified by #filter_parameter_logging.

Testing
-------

When you run your tests, you might notice that the Hoptoad service is recording
notices generated using #notify when you don't expect it to.  You can
use code like this in your test_helper.rb to redefine that method so those
errors are not reported while running tests.

    module HoptoadNotifier
      def self.notify(thing)
        # do nothing.
      end
    end

Proxy Support
-------------

The notifier supports using a proxy, if your server is not able to directly reach the Hoptoad servers.  To configure the proxy settings, added the following information to your Hoptoad configuration block.

    HoptoadNotifier.configure do |config|
      config.proxy_host = ...
      config.proxy_port = ...
      config.proxy_user = ...
      config.proxy_pass = ...

Supported Rails versions
------------------------

See SUPPORTED_RAILS_VERSIONS for a list of official supported versions of
Rails.

Please open up a support ticket on Tender ( http://help.hoptoadapp.com ) if
you're using a version of Rails that is not listed above and the notifier is
not working properly.

Javascript Notifer
------------------

To automatically include the Javascript node on every page, use this helper method from your layouts:

    <%= hoptoad_javascript_notifier %>

It's important to insert this very high in the markup, above all other javascript.  Example:

    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf8">
        <%= hoptoad_javascript_notifier %>
        <!-- more javascript -->
      </head>
      <body>
        ...
      </body>
    </html>

This helper will automatically use the API key, host, and port specified in the configuration.

Credits
-------

![thoughtbot](http://thoughtbot.com/images/tm/logo.png)

HoptoadNotifier is maintained and funded by [thoughtbot, inc](http://thoughtbot.com/community)

Thank you to all [the contributors](https://github.com/thoughtbot/hoptoad_notifier/contributors)!

The names and logos for thoughtbot are trademarks of thoughtbot, inc.

License
-------

HoptoadNotifier is Copyright © 2008-2011 thoughtbot. It is free software, and may be redistributed under the terms specified in the MIT-LICENSE file.
