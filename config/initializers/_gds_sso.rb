# This file is overwritten on deploy

# This file name has a leading _ to ensure it's loaded before devise_overrides.rb

require 'ostruct'

module GDS
  module SSO
    Config = OpenStruct.new({
      :oauth_id       => "abcdefghjasndjkasnderrbit",
      :oauth_secret   => "secret",
      :oauth_root_url => Plek.new.find('signon'),
    })
  end
end
