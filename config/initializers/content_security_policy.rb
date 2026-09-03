# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

require "securerandom"

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri :self
    policy.connect_src :self
    policy.font_src :self
    policy.form_action :self
    policy.frame_src :self
    policy.frame_ancestors :self
    policy.img_src :self, "https://secure.gravatar.com", :data
    policy.object_src :none
    policy.script_src :self
    policy.style_src :self
    policy.upgrade_insecure_requests if Rails.env.production?
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = ["script-src", "style-src"]
  config.content_security_policy_nonce_auto = true
end
