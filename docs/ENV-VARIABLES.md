# Which env variable you can use ?

Errbit can be almost configured by some ENVIRONMENT variables. If you
use this variable, you don't need copy all of you configuration file

To activate this env variable you need activate it by a Variable env.
You can do that with HEROKU or USE_ENV variable

If you activate it you can use all of this env variable :

## Errbit base configuration

* ERRBIT_HOST : the host of your errbit instance (not define by default)
* ERRBIT_EMAIL_FROM : the email sending all of your notification (not
  define by default )
* ERRBIT_CONFIRM_RESOLVE_ERR : define if you need confirm when you mark
  a problem resolve. ( true by default, fill it and you not need
confirm )
* ERRBIT_USER_HAS_USERNAME : allow identify your user by username
  instead of email. ( false by default, set to '1' to activate it)
* ERRBIT_ALLOW_COMMENTS_WITH_ISSUE_TRACKER : define if you activate the
  comment or not. By default comment are
* ERRBIT_ENFORCE_SSL : allow force the ssl on all the application. By
  default is false
* ERRBIT_USE_GRAVATAR : allow use gravatar to see user gravatar in user
  comment and page

## Authentification configuration

Environement variable allow define how you can auth on your errbit

### Github authentification

You can allow the GITHUB auth

* GITHUB_AUTHENTIFICATION : define if you allow the github auth. By
  default false
* GITHUB_CLIENT_ID : you github app client id to use in your github auth
* GITHUB_SECRET : your github app secret to use in your github auth
* GITHUB_ACCESS_SCOPE : The scope to ask to access on github account

## Email sending configuration

You can define how you connect your email sending system By all of this
information. All mail can be send only by SMTP if you use variable
system

* SMTP_SERVER
* SMTP_PORT
* SMTP_USERNAME
* SMTP_PASSWORD
* SMTP_DOMAIN

## MongoDB

You can define your MongoDB connection by 2 ways. If you have an URL,
you can define one of this ENV variables. All independently can works

* MONGOLAB_URI
* MONGOHQ_URL

If you have a complete MongoDB connection you can define it by all
information associate to your MongoDB connection. You need define all
variable.

* MONGOID_HOST
* MONGOID_PORT
* MONGOID_USERNAME
* MONGOID_PASSWORD
* MONGOID_DATABASE

## Flowdock notification adapter

If you noticed default Gravatar icon in your Flowdock notifications you
may want to [add Errbit icon](http://gravatar.com) for email that is
set in ERRBIT_EMAIL_FROM.
You don't need to approve or authorize it on Flowdock because it is used only for an icon.
