require "spec_helper"
require "heroku/helpers"
require "heroku-postgresql/client"
require 'digest'

describe HerokuPostgresql::Client do
  include Heroku::Helpers
  let(:url)     { 'postgres://somewhere/somedb' }
  let(:url_sha) { Digest::SHA2.hexdigest url }
  let(:client)  { HerokuPostgresql::Client.new(url) }

  it "sends an ingress request to the client" do
    url = "https://shogun.heroku.com/client/v10/databases/#{url_sha}/ingress"

    stub_request(:put, url).to_return(
      :body => json_encode({:message => "ok"}),
      :status => 200
    )

    client.ingress

    a_request(:put, url).should have_been_made.once
  end

  it "retries on error, then raises" do
    url = "https://shogun.heroku.com/client/v10/databases/#{url_sha}"
    stub_request(:get, url).to_return(:body => "error", :status => 500)
    client.stub(:sleep)
    lambda { client.get_database }.should raise_error RestClient::InternalServerError
    a_request(:get, url).should have_been_made.times(4)
  end

end
