require 'spec_helper'

describe "healthcheck endpoint" do

  it "should respond ok" do
    get "/healthcheck"

    expect(response.status).to eq(200)
    expect(response.body).to eq("OK")
  end
end
