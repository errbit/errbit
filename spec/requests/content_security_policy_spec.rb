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

  it "restricts fonts and frames to the application origin" do
    get new_user_session_path

    policy = response.headers.fetch("Content-Security-Policy")

    expect(policy).to include("font-src 'self'")
    expect(policy).to include("frame-src 'self'")
    expect(policy).not_to include("font-src 'self' https:")
    expect(policy).not_to include("font-src 'self' data:")
  end

  it "allows Gravatar images without allowing arbitrary HTTPS images" do
    get new_user_session_path

    policy = response.headers.fetch("Content-Security-Policy")

    expect(policy).to include("img-src 'self' https://secure.gravatar.com data:")
    expect(policy).not_to include("img-src 'self' https:;")
  end
end
