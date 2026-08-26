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
end
