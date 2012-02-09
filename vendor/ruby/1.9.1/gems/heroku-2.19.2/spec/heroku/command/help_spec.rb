require "spec_helper"
require "heroku/command/apps"
require "heroku/command/help"

describe Heroku::Command::Help do
  describe "Help.usage_for_command" do
    it "returns the usage if the command exists" do
      usage = Heroku::Command::Help.usage_for_command("help")
      usage.should == "Usage: heroku help [COMMAND]"
    end

    it "returns nil if command does not exist" do
      usage = Heroku::Command::Help.usage_for_command("bleahhaelihef")
      usage.should_not be
    end
  end

  describe "help" do
    it "should show root help with no args" do
      execute "help"
      output.should include "Usage: heroku COMMAND [--app APP] [command-specific-options]"
      output.should include "apps"
      output.should include "help"
    end

    it "should show command help and namespace help when ambigious" do
      execute "help apps"
      output.should include "heroku apps"
      output.should include "list your apps"
      output.should include "Additional commands"
      output.should include "apps:create"
    end

    it "should show only command help when not ambiguous" do
      execute "help apps:create"
      output.should include "heroku apps:create"
      output.should include "create a new app"
      output.should_not include "Additional commands"
    end

    it "should show command help with --help" do
      output = run "apps:create --help"
      output.should include "heroku apps:create"
      output.should include "create a new app"
      output.should_not include "Additional commands"
    end

    it "should show that the command is an alias" do
      execute "help create"
      output.should include "heroku apps:create"
    end

    it "should show if the command does not exist" do
      execute "help sudo:sandwich"
      output.strip.should_not be_empty
      output.should include "sudo:sandwich is not a heroku command. See 'heroku help'."
    end

    it "should show help with naked -h" do
      output = run("-h")
      output.should include "Usage: heroku COMMAND"
    end

    it "should show help with naked --help" do
      output = run("--help")
      output.should include "Usage: heroku COMMAND"
    end

    describe "with legacy help" do
      require "helper/legacy_help"

      it "displays the legacy group in the namespace list" do
        execute "help"
        output.should include "Foo Group"
      end

      it "displays group help" do
        execute "help foo"
        output.should include "do a bar to foo"
        output.should include "do a baz to foo"
      end

      it "displays legacy command-specific help" do
        execute "help foo:bar"
        output.should include "do a bar to foo"
      end
    end
  end
end
