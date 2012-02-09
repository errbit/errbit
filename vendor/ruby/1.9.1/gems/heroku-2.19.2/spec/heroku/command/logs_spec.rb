require "spec_helper"
require "heroku/command/logs"

describe Heroku::Command::Logs do
  describe "logs" do
    it "runs with no options" do
      stub_core.read_logs("myapp", [])
      execute "logs"
    end

    it "runs with options" do
      stub_core.read_logs("myapp", [
        "tail=1",
        "num=2",
        "ps=ps.3",
        "source=source.4"
      ])
      execute "logs --tail --num 2 --ps ps.3 --source source.4"
    end

    describe "with log output" do
      before(:each) do
        stub_core.read_logs("myapp", []).yields("2011-01-01T00:00:00+00:00 app[web.1]: test")
      end

      it "prettifies output" do
        execute "logs"
        output.should == "\e[36m2011-01-01T00:00:00+00:00 app[web.1]:\e[0m test"
      end

      it "does not use ansi if stdout is not a tty" do
        extend RR::Adapters::RRMethods
        stub(STDOUT).isatty.returns(false)
        execute "logs"
        output.should == "2011-01-01T00:00:00+00:00 app[web.1]: test"
        stub(STDOUT).isatty.returns(true)
      end

      it "does not use ansi if TERM is not set" do
        term = ENV.delete("TERM")
        execute "logs"
        output.should == "2011-01-01T00:00:00+00:00 app[web.1]: test"
        ENV["TERM"] = term
      end
    end
  end

  describe "deprecated logs:cron" do
    it "can view cron logs" do
      stub_core.cron_logs("myapp").returns("the_cron_logs")
      execute "logs:cron"
      output.should =~ /the_cron_logs/
    end
  end

end
