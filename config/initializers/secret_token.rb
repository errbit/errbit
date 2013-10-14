# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

# Everyone can share the same token for development/test
if ENV['SECRET_TOKEN'].present?
  Errbit::Application.config.secret_token = ENV['SECRET_TOKEN']

  # Do not raise an error if secret token is not available during assets precompilation
elsif %w(development test).include?(Rails.env) || ENV['RAILS_GROUPS'] == 'assets'
  Errbit::Application.config.secret_token = 'f258ed69266dc8ad0ca79363c3d2f945c388a9c5920fc9a1ae99a98fbb619f135001c6434849b625884a9405a60cd3d50fc3e3b07ecd38cbed7406a4fccdb59c'
elsif !Errbit::Application.config.secret_token
  raise <<-ERROR

  You must generate a unique secret token for your Errbit instance.

  If you are deploying via capistrano, please ensure that your `config/deploy.rb` contains
  the new `errbit:setup_configs` and `errbit:symlink_configs` tasks from `config/deploy.example.rb`.
  Next time you deploy, your secret token will be automatically generated.

  If you are deploying to Heroku, please run the following command to set your secret token:
      heroku config:add SECRET_TOKEN="$(bundle exec rake secret)"

  If you are deploying in some other way, please run the following command to generate a new secret token,
  and commit the new `config/initializers/__secret_token.rb`:

      echo "Errbit::Application.config.secret_token = '$(bundle exec rake secret)'" > config/initializers/__secret_token.rb

  ERROR
end

Devise.secret_key = Errbit::Application.config.secret_token
