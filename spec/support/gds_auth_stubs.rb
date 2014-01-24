module GdsAuthStubs
  def gds_omniauth_hash_stub(uid, details = {})
    details = {
      :name => "Test User",
      :email => "test@example.com",
      :permissions => ['signin']
    }.merge(details)

    Hashie::Mash.new(
      'provider' => 'gds',
      'uid' => uid,
      'info' => {
        'name' => details[:name],
        'email' => details[:email],
      },
      'extra' => {
        "user" => {
          "uid" => uid,
          "name" => details[:name],
          "email" => details[:email],
          "permissions" => details[:permissions],
        },
      },
      'credentials' => {
        'token' => Devise.friendly_token,
      }
    )
  end
end

RSpec.configuration.include GdsAuthStubs
