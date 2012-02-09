require "spec_helper"
require "heroku/helpers"
require "heroku-shared-postgresql/client"
require 'digest'

def yobuko_path(path)
  "https://heroku-shared-production.herokuapp.com/client/#{path}"
end

def hk_pg_api_stub(method, path)
  stub_request(method, yobuko_path(path))
end

def hk_pg_api_request(method, path)
  a_request(method, yobuko_path(path))
end

describe HerokuSharedPostgresql::Client do
  include Heroku::Helpers
  let(:url)     { 'postgres://mountain/spirit' }
  let(:client)  { HerokuSharedPostgresql::Client.new(url) }

  it 'it fails to get info data due to authorization' do
    hk_pg_api_stub(:get, "/info").to_return(:status => 401)
  end
end
