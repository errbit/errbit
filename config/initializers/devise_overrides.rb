Warden::OAuth2.configure do |config|
  config.token_model = GDSBearerToken
end

Devise.setup do |config|
  config.omniauth :gds,
    GDS::SSO::Config.oauth_id,
    GDS::SSO::Config.oauth_secret,
    :client_options => {
      :site => GDS::SSO::Config.oauth_root_url,
      :authorize_url => "/oauth/authorize",
      :token_url => "/oauth/access_token",
    }

  config.warden do |manager|
    manager.strategies.add(:gds_bearer_token, Warden::OAuth2::Strategies::Bearer)
    manager.default_strategies(:scope => :user).unshift :gds_bearer_token
  end
end
