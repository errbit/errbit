# frozen_string_literal: true

OmniAuth.config.test_mode = true

OmniAuth.config.mock_auth[:github] = Faker::Omniauth.github(name: "nashby")
