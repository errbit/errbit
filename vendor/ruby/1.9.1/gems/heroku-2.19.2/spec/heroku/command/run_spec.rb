require "spec_helper"
require "heroku/command/run"

describe Heroku::Command::Run do
  describe "run:rake" do
    it "runs a rake command" do
      stub_core.start("myapp", "rake foo", :attached).returns(["rake_output"])
      execute "run:rake foo"
      output.should =~ /rake_output/
    end

    it "requires a command" do
      lambda { execute "run:rake" }.should fail_command("Usage: heroku run:rake COMMAND")
    end

    it "gets an http APP_CRASHED" do
      stub_core.start("myapp", "rake foo", :attached) { raise(Heroku::Client::AppCrashed, "error_page") }
      execute "run:rake foo"
      output.should =~ /Couldn't run rake\nerror_page/
    end
  end

  describe "run:console" do
    it "runs a console session" do
      console = stub(Heroku::Client::ConsoleSession)
      stub_core.console.returns(console)
      execute "run:console"
    end

    it "runs a console command" do
      stub_core.console("myapp", "bash foo").returns("foo_output")
      execute "run:console bash foo"
      output.should =~ /foo_output/
    end
  end
end
