class GDSBearerToken

  def self.locate(token_string)
    access_token = OAuth2::AccessToken.new(oauth_client, token_string)
    response_body = access_token.get("/user.json?client_id=#{CGI.escape(GDS::SSO::Config.oauth_id)}").body
    user_details = omniauth_style_response(response_body)
    User.find_for_gds_oauth(user_details)
  rescue OAuth2::Error
    nil
  end

  def self.oauth_client
    @oauth_client ||= OAuth2::Client.new(
      GDS::SSO::Config.oauth_id,
      GDS::SSO::Config.oauth_secret,
      :site => GDS::SSO::Config.oauth_root_url
    )
  end

  def self.omniauth_style_response(response_body)
    input = Yajl::Parser.parse(response_body)['user']

    {
      'uid' => input['uid'],
      'info' => {
        'email' => input['email'],
        'name' => input['name']
      },
      'extra' => {
        'user' => {
          'permissions' => input['permissions'],
          'organisation_slug' => input['organisation_slug'],
        }
      }
    }
  end
end
