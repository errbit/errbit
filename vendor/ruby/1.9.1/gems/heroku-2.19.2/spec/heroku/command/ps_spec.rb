require "spec_helper"
require "heroku/command/ps"

describe Heroku::Command::Ps do
  describe "ps:dynos" do
    it "displays the current number of dynos" do
      stub_core.info("myapp").returns(:dynos => 5)
      execute "ps:dynos"
      output.should =~ /myapp is running 5 dynos/
    end

    it "sets the number of dynos" do
      stub_core.set_dynos("myapp", "5").returns(5)
      execute "ps:dynos 5"
      output.should =~ /myapp now running 5 dynos/
    end

    it "errors out on cedar apps" do
      stub_core.info("myapp").returns(:dynos => 5, :stack => "cedar")
      lambda { execute "ps:dynos" }.should raise_error(Heroku::Command::CommandFailed)
    end
  end

  describe "ps:workers" do
    it "displays the current number of workers" do
      stub_core.info("myapp").returns(:workers => 5)
      execute "ps:workers"
      output.should =~ /myapp is running 5 workers/
    end

    it "sets the number of workers" do
      stub_core.set_workers("myapp", "5").returns(5)
      execute "ps:workers 5"
      output.should =~ /myapp now running 5 workers/
    end

    it "errors out on cedar apps" do
      stub_core.info("myapp").returns(:workers => 5, :stack => "cedar")
      lambda { execute "ps:dynos" }.should raise_error(Heroku::Command::CommandFailed)
    end
  end

  describe "ps" do
    before(:each) do
      stub_core.ps("myapp").returns([
        { "process" => "ps.1", "state" => "running", "elapsed" => 600, "command" => "bin/bash ps1" },
        { "process" => "ps.2", "state" => "running", "elapsed" => 600, "command" => "bin/bash ps2" }
      ])
    end

    it "displays processes" do
      execute "ps"
      output.should =~ /ps\.1\s+running for 10m\s+bin\/bash ps1/
    end
  end

  describe "ps:restart" do
    it "restarts all processes with no args" do
      stub_core.ps_restart("myapp", {})
      execute "ps:restart"
      output.should =~ /Restarting processes/
    end

    it "restarts one process" do
      stub_core.ps_restart("myapp", :ps => "ps.1")
      execute "ps:restart ps.1"
      output.should =~ /Restarting ps.1 process/
    end

    it "restarts a type of process" do
      stub_core.ps_restart("myapp", :type => "ps")
      execute "ps:restart ps"
      output.should =~ /Restarting ps processes/
    end
  end

  describe "ps:scale" do
    it "can scale one process" do
      stub_core.ps_scale("myapp", :type => "ps", :qty => "5")
      execute "ps:scale ps 5"
    end

    it "can scale using key/value format" do
      stub_core.ps_scale("myapp", :type => "ps", :qty => "5")
      execute "ps:scale ps=5"
    end

    it "can scale relative amounts" do
      stub_core.ps_scale("myapp", :type => "ps", :qty => "+2")
      stub_core.ps_scale("myapp", :type => "sp", :qty => "-2")
      stub_core.ps_scale("myapp", :type => "ot", :qty => "7")
      execute "ps:scale ps+2 sp-2 ot=7"
    end

    it "can scale a process with a number in its name" do
      stub_core.ps_scale("myapp", :type => "ps2web", :qty => "5")
      execute "ps:scale ps2web=5"
    end
  end
end
