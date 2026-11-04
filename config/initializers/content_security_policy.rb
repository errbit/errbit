# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Origins the "Sign in with ..." buttons send the browser to.
#
# jquery-ujs turns those links into real form submissions, and omniauth
# answers them with a redirect to the provider. Chrome checks form-action
# against the target of such a redirect, Firefox only against the form's own
# action, so without the provider's origin here the button silently does
# nothing in Chrome while working in Firefox.
sign_in_origins = lambda do
  origin = lambda do |url|
    uri = URI.parse(url.to_s)
    next nil unless uri.scheme && uri.host

    port = (uri.port && uri.port != uri.default_port) ? ":#{uri.port}" : ""
    "#{uri.scheme}://#{uri.host}#{port}"
  rescue URI::InvalidURIError
    nil
  end

  origins = []
  origins << origin.call(Errbit::Config.github_url) if Errbit::Config.github_authentication
  origins << "https://accounts.google.com" if Errbit::Config.google_authentication
  # The authorization endpoint comes from the provider's discovery document,
  # which is not available this early; every provider worth the name serves it
  # from the issuer's own origin.
  origins << origin.call(Errbit::Config.oidc_issuer) if Errbit::Config.oidc_authentication
  # ... and whatever else the installation knows it needs, for a provider that
  # serves its authorization endpoint from another host, or an instance that
  # is pointed at a different provider from time to time.
  origins.concat(Array(Errbit::Config.csp_form_action_origins).map { |url| origin.call(url) })
  origins.compact.uniq
end.call

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri :self
    policy.connect_src :self
    policy.font_src :self
    policy.form_action :self, *sign_in_origins
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
