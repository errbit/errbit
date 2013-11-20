Errbit::Application.config.secret_token = '<%= ENV['SECRET_TOKEN'] %>'
Devise.secret_key = Errbit::Application.config.secret_token
