require "spec_helper"
require "heroku/command/version"

module Heroku::Command
  describe Version do
    before(:each) do
      @cli = prepare_command(Version)
      @cli.stub(:options).and_return(:app => "myapp")
    end

    it "shows app info using the --app syntax" do
      @cli.should_receive(:display).with("heroku-gem/#{Heroku::VERSION}")
      @cli.index
    end
  end
end
