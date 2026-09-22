# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Content Security Policy", type: :request do
  it "includes the nonce on executable script tags" do
    get new_user_session_path

    nonce = response.headers.fetch("Content-Security-Policy").match(/nonce-([^' ]+)/)[1]

    expect(response.body).to match(/<script[^>]+nonce="#{Regexp.escape(nonce)}"/)
  end

  it "generates a different nonce for each response" do
    get new_user_session_path
    first_nonce = response.headers.fetch("Content-Security-Policy").match(/nonce-([^' ]+)/)[1]

    get new_user_session_path
    second_nonce = response.headers.fetch("Content-Security-Policy").match(/nonce-([^' ]+)/)[1]

    expect(second_nonce).not_to eq(first_nonce)
  end

  it "is expected to set Content Security Policy headers" do
    # stub SecureRandom.base64 to verify nonce-es values
    expect(SecureRandom).to receive(:base64).and_return("U6sDCLHA1gHdzM7vepm6dA==")

    get new_user_session_path

    policies = response.headers.fetch("Content-Security-Policy").split(";").map(&:strip)

    expect(policies).to include("default-src 'self'")

    expect(policies).to include("base-uri 'self'")

    expect(policies).to include("connect-src 'self'")

    expect(policies).to include("font-src 'self'")

    expect(policies).to include("form-action 'self' #{Errbit::Config.github_url} https://accounts.google.com")

    expect(policies).to include("frame-src 'self'")

    expect(policies).to include("frame-ancestors 'self'")

    expect(policies).to include("img-src 'self' https://secure.gravatar.com data:")

    expect(policies).to include("object-src 'none'")

    expect(policies).to include("script-src 'self' 'nonce-U6sDCLHA1gHdzM7vepm6dA=='")

    expect(policies).to include("style-src 'self' 'nonce-U6sDCLHA1gHdzM7vepm6dA=='")

    expect(policies).to include("upgrade-insecure-requests")
  end
end
