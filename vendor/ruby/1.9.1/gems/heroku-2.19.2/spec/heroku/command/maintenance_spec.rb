require "spec_helper"
require "heroku/command/maintenance"

module Heroku::Command
  describe Maintenance do
    before do
      @m = prepare_command(Maintenance)
    end

    it "turns on maintenance mode for the app" do
      @m.heroku.should_receive(:maintenance).with('myapp', :on)
      @m.should_receive(:display).with('Maintenance mode enabled.')
      @m.on
    end

    it "turns off maintenance mode for the app" do
      @m.heroku.should_receive(:maintenance).with('myapp', :off)
      @m.should_receive(:display).with('Maintenance mode disabled.')
      @m.off
    end
  end
end
