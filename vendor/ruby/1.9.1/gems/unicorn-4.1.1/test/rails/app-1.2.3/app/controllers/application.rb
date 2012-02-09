# -*- encoding: binary -*-

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => "_unicorn_rails_test.#{rand}"
end
