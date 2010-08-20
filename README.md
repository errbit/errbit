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

  1. Install MongoDB
    * Follow the directions [here](http://www.mongodb.org/display/DOCS/Ubuntu+and+Debian+packages), then:
      
            aptitude update
            aptitude install mongodb
      
  2. Install libxml
    
        apt-get install libxml2 libxml2-dev libxslt-dev
        
  3. Install Bundler
  
         gem install bundler --pre
         
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

TODO
----

* Add a deployment view
* Add ability for watchers to be configured for types of notifications they should receive

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
