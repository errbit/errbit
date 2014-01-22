Devise.setup do |config|
  config.omniauth :gds,
    GDS::SSO::Config.oauth_id,
    GDS::SSO::Config.oauth_secret,
    :client_options => {
      :site => GDS::SSO::Config.oauth_root_url,
      :authorize_url => "/oauth/authorize",
      :token_url => "/oauth/access_token",
    }
end
