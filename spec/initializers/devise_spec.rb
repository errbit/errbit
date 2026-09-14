# frozen_string_literal: true

require "rails_helper"

RSpec.describe Devise do
  def load_initializer
    load File.join(Rails.root, "config", "initializers", "devise.rb")
  end

  after do
    # reset to the defaults
    allow(Errbit::Config).to receive(:oidc_authentication).and_return(false)
    load_initializer
  end

  describe "omniauth github" do
    it "sets the client options correctly for the default github_url" do
      load_initializer

      options = Devise.omniauth_configs[:github].options
      expect(options).to have_key(:client_options)
      expect(options[:client_options]).to eq(
        site: "https://api.github.com",
        authorize_url: "https://github.com/login/oauth/authorize",
        token_url: "https://github.com/login/oauth/access_token"
      )
    end

    it "sets the client options correctly for the a GitHub Enterprise github_url" do
      allow(Errbit::Config).to receive(:github_url).and_return("https://github.example.com")
      allow(Errbit::Config).to receive(:github_api_url).and_return("https://github.example.com/api/v3")
      load_initializer

      options = Devise.omniauth_configs[:github].options
      expect(options).to have_key(:client_options)
      expect(options[:client_options]).to eq(
        site: "https://github.example.com/api/v3",
        authorize_url: "https://github.example.com/login/oauth/authorize",
        token_url: "https://github.example.com/login/oauth/access_token"
      )
    end
  end

  describe "omniauth openid connect" do
    before do
      allow(Errbit::Config).to receive(:oidc_authentication).and_return(true)
      allow(Errbit::Config).to receive(:oidc_issuer).and_return("https://issuer.example.com")
      allow(Errbit::Config).to receive(:oidc_client_id).and_return("client-id")
      allow(Errbit::Config).to receive(:oidc_secret).and_return("secret")
      allow(Errbit::Config).to receive(:oidc_redirect_uri).and_return("https://errbit.example.com/users/auth/openid_connect/callback")
      allow(Errbit::Config).to receive(:oidc_scopes).and_return("openid,profile,groups")
      allow(Errbit::Config).to receive(:oidc_uid_field).and_return("sub")
    end

    it "keeps the callback name fixed and accepts arbitrary scopes" do
      load_initializer

      config = Devise.omniauth_configs[:openid_connect]

      expect(config.options[:name]).to eq(:openid_connect)
      expect(config.options[:scope]).to eq(%w[openid profile groups])
      expect(config.options[:uid_field]).to eq("sub")
      expect(config.options[:client_options]).to include(
        host: "issuer.example.com", scheme: "https", port: 443
      )
    end

    it "requires provider settings when enabled" do
      allow(Errbit::Config).to receive(:oidc_issuer).and_return(nil)
      allow(Errbit::Config).to receive(:oidc_client_id).and_return(nil)
      allow(Errbit::Config).to receive(:oidc_secret).and_return(nil)
      allow(Errbit::Config).to receive(:oidc_redirect_uri).and_return(nil)

      expect { load_initializer }.to raise_error(ArgumentError, /Missing OIDC configuration/)
    end

    it "rejects an invalid issuer when enabled" do
      allow(Errbit::Config).to receive(:oidc_issuer).and_return("not a URL %")

      expect { load_initializer }.to raise_error(ArgumentError, /OIDC_ISSUER/)
    end

    it "rejects an issuer without an HTTPS host" do
      allow(Errbit::Config).to receive(:oidc_issuer).and_return("issuer.example.com")

      expect { load_initializer }.to raise_error(ArgumentError, /OIDC_ISSUER/)
    end

    it "rejects a non-HTTPS issuer" do
      allow(Errbit::Config).to receive(:oidc_issuer).and_return("http://issuer.example.com")

      expect { load_initializer }.to raise_error(ArgumentError, /HTTPS issuer/)
    end

    it "rejects an issuer with a query or fragment" do
      ["https://issuer.example.com?tenant=foo", "https://issuer.example.com/#fragment"].each do |issuer|
        allow(Errbit::Config).to receive(:oidc_issuer).and_return(issuer)

        expect { load_initializer }.to raise_error(ArgumentError, /query or fragment/)
      end
    end

    it "allows issuer paths" do
      allow(Errbit::Config).to receive(:oidc_issuer).and_return("https://issuer.example.com/realms/errbit")
      load_initializer

      config = Devise.omniauth_configs[:openid_connect]

      expect(config.options[:client_options]).to include(host: "issuer.example.com", port: 443)
    end
  end
end
