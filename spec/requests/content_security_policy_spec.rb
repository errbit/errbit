# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Content Security Policy", type: :request do
  it "generates a different nonce for each response" do
    get new_user_session_path
    first_nonce = response.headers.fetch("content-security-policy").match(/nonce-([^' ]+)/)[1]

    get new_user_session_path
    second_nonce = response.headers.fetch("content-security-policy").match(/nonce-([^' ]+)/)[1]

    expect(second_nonce).not_to eq(first_nonce)
  end

  it "is expected to set CSP headers with nonce equal to csp-nonce from response html" do
    get new_user_session_path

    nonce = Nokogiri::HTML5(response.body).at_css("meta[name='csp-nonce']").attribute("content").value

    expect(nonce.present?).to eq(true)

    policies = response.headers.fetch("content-security-policy").split(";").map(&:strip)

    expect(policies).to include("default-src 'self'")

    expect(policies).to include("base-uri 'self'")

    expect(policies).to include("connect-src 'self'")

    expect(policies).to include("font-src 'self'")

    expect(policies).to include("form-action 'self' #{Errbit::Config.github_url} https://accounts.google.com")

    expect(policies).to include("frame-src 'self'")

    expect(policies).to include("frame-ancestors 'self'")

    expect(policies).to include("img-src 'self' https://secure.gravatar.com data:")

    expect(policies).to include("object-src 'none'")

    expect(policies).to include("script-src 'self' 'nonce-#{nonce}'")

    expect(policies).to include("style-src 'self' 'nonce-#{nonce}'")

    expect(policies).to include("upgrade-insecure-requests")
  end

  it "is expected to include nonce for <script> tags" do
    get new_user_session_path

    # binding.pry

    nonce = response.headers.fetch("Content-Security-Policy").match(/nonce-([^' ]+)/)[1]

    expect(response.body).to match(/<script src=[^>]+nonce="#{Regexp.escape(nonce)}"/)

    expect(response.body).to match(/<script type=[^>]+nonce="#{Regexp.escape(nonce)}"/)

    true
  end
end
