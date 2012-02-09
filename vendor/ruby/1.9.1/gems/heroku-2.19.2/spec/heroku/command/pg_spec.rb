require "spec_helper"
require "heroku/command/pg"

module Heroku::Command
  describe Pg do
    before do
      @pg = prepare_command(Pg)
      @pg.stub!(:config_vars).and_return({
        "DATABASE_URL" => "postgres://database_url",
        "SHARED_DATABASE_URL" => "postgres://other_database_url",
        "HEROKU_POSTGRESQL_RONIN_URL" => "postgres://database_url",
      })
      @pg.stub!(:args).and_return ["DATABASE_URL"]
      @pg.heroku.stub!(:info).and_return({})
    end

    it "resets the app's database if user confirms" do
      @pg.stub!(:confirm_command).and_return(true)

      fake_client = mock("heroku_postgresql_client")
      fake_client.should_receive("reset")

      @pg.should_receive(:heroku_postgresql_client).with("postgres://database_url").and_return(fake_client)

      @pg.reset
    end

    it "doesn't reset the app's database if the user doesn't confirm" do
      @pg.stub!(:confirm_command).and_return(false)
      @pg.should_not_receive(:heroku_postgresql_client)
      @pg.reset
    end

    context "info" do
      it "requests the info from the server" do
        fake_client = mock("heroku_postgresql_client")
        fake_client.should_receive("get_database").and_return(:info => [
          {'name' => "State", 'value' => "available"},
          {'name' => "whatever", 'values' => ['one', 'eh']}
        ])

        @pg.should_receive(:heroku_postgresql_client).with("postgres://database_url").and_return(fake_client)
        @pg.info
      end
    end

    context "promotion" do
      it "promotes the specified database" do
        @pg.stub!(:args).and_return ["SHARED_DATABASE_URL"]
        @pg.stub!(:confirm_command).and_return(true)
        @pg.heroku.should_receive(:add_config_vars).with("myapp", {"DATABASE_URL" => "postgres://other_database_url"})

        @pg.promote
      end

      it "promotes the specified database url case-sensitively" do
        @pg.stub!(:args).and_return ["postgres://john:S3nsit1ve@my.example.com/db_name"]
        @pg.stub!(:confirm_command).and_return(true)
        @pg.heroku.should_receive(:add_config_vars).with("myapp", {"DATABASE_URL" => "postgres://john:S3nsit1ve@my.example.com/db_name"})

        @pg.promote
      end

      it "fails if no database is specified" do
        @pg.stub(:args).and_return []
        @pg.stub!(:confirm_command).and_return(true)

        @pg.heroku.should_not_receive(:add_config_vars)
        @pg.should_receive(:error).with("Usage: heroku pg:promote <DATABASE>").and_raise(SystemExit)

        lambda { @pg.promote }.should raise_error SystemExit
      end

      it "does not repromote the current DATABASE_URL" do
        @pg.stub(:options).and_return(:db => "HEROKU_POSTGRESQL_RONIN")
        @pg.stub!(:confirm_command).and_return(true)

        @pg.heroku.should_not_receive(:add_config_vars)
        @pg.should_receive(:error).with("DATABASE_URL is already set to HEROKU_POSTGRESQL_RONIN").and_raise(SystemExit)

        lambda { @pg.promote }.should raise_error SystemExit
      end

      it "does not promote DATABASE_URL" do
        @pg.stub(:args).and_return(['DATABASE_URL'])
        @pg.stub!(:confirm_command).and_return(true)

        @pg.heroku.should_not_receive(:add_config_vars)
        @pg.should_receive(:error).with("DATABASE_URL is already set to HEROKU_POSTGRESQL_RONIN").and_raise(SystemExit)

        lambda { @pg.promote }.should raise_error SystemExit
      end
    end
  end
end
