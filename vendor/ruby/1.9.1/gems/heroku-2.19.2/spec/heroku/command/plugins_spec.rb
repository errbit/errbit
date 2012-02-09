require "spec_helper"
require "heroku/command/plugins"

module Heroku::Command
  include SandboxHelper

  describe Plugins do
    before do
      @command = prepare_command(Plugins)
      @plugin  = mock('heroku plugin')
      @plugin.stub(:name).and_return("some_plugin")
    end

    it "installs plugins" do
      @command.stub!(:args).and_return(['git://github.com/heroku/plugin.git'])
      Heroku::Plugin.should_receive(:new).with('git://github.com/heroku/plugin.git').and_return(@plugin)
      Heroku::Plugin.should_receive(:load_plugin).and_return(true)
      @plugin.should_receive(:install).and_return(true)
      @command.install
    end

    it "uninstalls plugins" do
      @command.stub!(:args).and_return(['plugin'])
      Heroku::Plugin.should_receive(:new).with('plugin').and_return(@plugin)
      @plugin.should_receive(:uninstall)
      @command.uninstall
    end

    it "does not install plugins that do not load" do
      @command.stub!(:args).and_return(['git://github.com/heroku/plugin.git'])
      Heroku::Plugin.should_receive(:new).with('git://github.com/heroku/plugin.git').and_return(@plugin)
      Heroku::Plugin.should_receive(:load_plugin).and_raise("error")
      @plugin.should_receive(:install).and_return(true)
      @command.should_receive(:installation_failed).with(@plugin, "error")
      @command.install
    end
  end
end
