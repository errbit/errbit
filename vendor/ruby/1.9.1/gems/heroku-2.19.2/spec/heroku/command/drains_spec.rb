require "spec_helper"
require "heroku/command/drains"

describe Heroku::Command::Drains do

  describe "drains" do
    it "can list drains" do
      stub_core.list_drains("myapp").returns("drains")
      execute "drains"
      output.should == "drains"
    end

    it "can add drains" do
      stub_core.add_drain("myapp", "syslog://localhost/add").returns("added")
      execute "drains:add syslog://localhost/add"
      output.should == "added"
    end

    it "can remove drains" do
      stub_core.remove_drain("myapp", "syslog://localhost/remove").returns("removed")
      execute "drains:remove syslog://localhost/remove"
      output.should == "removed"
    end
  end
end
