# Deploy to Heroku

## The Easy Way

If you just want to get started with Errbit and you're not sure how to proceed,
you can use this deploy button to get a basic deployment running on Heroku.

You will need to spin up a MongoDB server if you don't have one at your disposal already.
Free clusters up to 512MB are available with MongoDB Atlas [Here](https://cloud.mongodb.com)

## MongoDB Atlas Setup for Quick Deployment

Upon creating an account, you will be greeted with this page. Make sure you select Starter Cluster.

![Cluster selection](./example/atlas1.jpg)

After this, you will be taken to the below screen:

![Server selection](./example/atlas2.png)

Select one of the servers marked with `FREE TIER AVAILABLE` and click on `Create Cluster`. It will only take a couple of minutes to configure everything for you.

Follow the "Getting Started" tutorial on the bottom left.

### Create a database user

Go to the `Database Access` section in the `security` tab. Click on `+ Add New User` to create a new user, whereupon a new screen will pop up. Select `Read and write to any database`, so the bot can properly store the data. Choose a username and password, but make sure they both **don't contain any special character** like `!`, `-`, `?`. Copy the password into your notepad.

Finally, click `Add User` to finish the creation.

![Create User](./example/atlas3.png)

### Whitelist all IP's

Go to the `Network Access` section in the `security` tab. Click on `+ Add IP Address` to add an IP address, whereupon a new screen will pop up. Click the `Allow Access From Everywhere` button and `0.0.0.0/0` should appear in the `Whitelist Entry`. Otherwise, make sure to put input that manually. Finally, click `Confirm` to confirm your changes.

![Whitelisting IPs](./example/atlas4.png)

### Obtain a connection string

The last part is to generate a Mongo URI. Go to the `Clusters` section in the `Atlas` tab. Click on `Connect` on the left side of your Cluster dashboard. This will open up a new screen where you have three options. For our purposes, select the middle option `Connect Your Application`.

![Connection String](./example/atlas5.png)

Be sure to select Ruby and Version 2.7 or later.
You need to copy the connection string, which can be easily done by clicking the `Copy` button. Then replace `<password>` with the password for your user, which you set earlier. Paste the URI in your notepad.

The final URI looks similar to this: `mongodb+srv://Username:MyPassword@modmail-kjvn21.mongodb.net/`.

![Connection String - 2](./example/atlas6.png)

Now that you have your connection URI, click the deploy button below and start your app deployment. Paste the entire URI you obtained from above into the MONGODB_URI Text box.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/errbit/errbit/tree/master)

After deploying the application, you still need to run `rake errbit:bootstrap`
to create indexes and get your admin user set up. You can do this by clicking the `Run Console` button in the More dropdown button of your new Heroku app. Then paste the rake command above and be sure to copy your admin credentials!

![Run Console](./example/atlas7.png)

## The Hard Way

We designed Errbit to work well with Heroku. These instructions should result
in a working deploy, but you should modify them to suit your needs:

### Clone and prepare the source code repository
```bash
git clone git@github.com:errbit/errbit.git
cd errbit
```

- Update `db/seeds.rb` with admin credentials for your initial login

Commit the results:
```bash
git commit -m "Update db/seeds.rb with initial login"
```

### Install the heroku toolbelt
[toolbelt.heroku.com](https://toolbelt.heroku.com/)

### Create an app on Heroku and push the source code. Use the above documentation to obtain a MongoDB URI from MongoDB Atlas if you don't have one.
```bash
heroku apps:create
heroku addons:create sendgrid:starter
heroku config:set GEMFILE_RUBY_VERSION=2.7.5
heroku config:set SECRET_KEY_BASE="$(bundle exec rake secret)"
heroku config:set MONGODB_URI="<URI HERE>"
heroku config:set ERRBIT_HOST=some-hostname.example.com
heroku config:set ERRBIT_EMAIL_FROM=example@example.com
heroku config:set EMAIL_DELIVERY_METHOD=smtp SMTP_SERVER=smtp.sendgrid.net
git push heroku master
```

### Prepare the DB

```bash
heroku run rake errbit:bootstrap
```

### Schedule recurring tasks
You may want to periodically clear resolved errors to free up space. For that
you have a few options:

Option 1. With the heroku-scheduler add-on (replacement for cron):

```bash
# Install the heroku scheduler add-on
heroku addons:create scheduler:standard

# Go open the dashboard to schedule the job.  You should use
# 'rake errbit:clear_resolved' as the task command, and schedule it
# at whatever frequency you like (once/day should work great).
heroku addons:create scheduler
```

Option 2. With the cron add-on:

```bash
# Install the heroku cron addon, to clear resolved errors daily:
heroku addons:create cron:daily
```

Option 3. Clear resolved errors manually:

```bash
heroku run rake errbit:clear_resolved
```
