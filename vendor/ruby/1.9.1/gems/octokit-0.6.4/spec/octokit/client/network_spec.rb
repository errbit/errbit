# -*- encoding: utf-8 -*-
require 'helper'

describe Octokit::Client::Network do

  before do
    @client = Octokit::Client.new(:login => 'sferik')
  end

  describe ".network_meta" do

    it "should return network meta" do
      stub_get("https://github.com/sferik/rails_admin/network_meta").
        to_return(:body => fixture("v2/network_meta.json"))
      network_meta = @client.network_meta("sferik/rails_admin")
      network_meta.blocks.first.name.should == "sferik"
    end

  end

  describe ".network_data" do

    it "should return network data" do
      stub_get("https://github.com/sferik/rails_admin/network_data_chunk").
        to_return(:body => fixture("v2/network_data.json"))
      network_data = @client.network_data("sferik/rails_admin")
      network_data.first.login.should == "rosenfeld"
    end

  end

end
