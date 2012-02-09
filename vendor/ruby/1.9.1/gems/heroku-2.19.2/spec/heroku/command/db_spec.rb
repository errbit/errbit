require "spec_helper"
require "heroku/command/db"

module Heroku::Command
  describe Db do
    before do
      @db = prepare_command(Db)
      @taps_client = mock('taps client')
    end

    it "pull database" do
      @db.stub!(:args).and_return(['postgres://postgres@localhost/db'])
      opts = { :database_url => 'postgres://postgres@localhost/db', :default_chunksize => 1000, :indexes_first => true }
      @db.should_receive(:taps_client).with(:pull, opts)
      @db.should_receive(:confirm_command).and_return(true)
      @db.pull
    end

    it "push database" do
      @db.stub!(:args).and_return(['postgres://postgres@localhost/db'])
      opts = { :database_url => 'postgres://postgres@localhost/db', :default_chunksize => 1000, :indexes_first => true }
      @db.should_receive(:taps_client).with(:push, opts)
      @db.should_receive(:confirm_command).and_return(true)
      @db.push
    end

    describe "without PostgreSQL" do
      it "defaults host to 127.0.0.1 with a username" do
        @db.send(:uri_hash_to_url, {'scheme' => 'db', 'username' => 'user', 'path' => 'database'}).should == 'db://user@127.0.0.1/database'
      end
    end

    describe "with PostgreSQL" do
      it "handles lack of host as UNIX domain socket connection" do
        @db.send(:uri_hash_to_url, {'scheme' => 'postgres', 'path' => 'database'}).should == 'postgres:/database'
      end
    end

    it "handles the lack of a username properly" do
      @db.send(:uri_hash_to_url, {'scheme' => 'db', 'path' => 'database'}).should == 'db://127.0.0.1/database'
    end

    it "handles integer port number" do
      @db.send(:uri_hash_to_url, {'scheme' => 'db', 'path' => 'database', 'port' => 9000}).should == 'db://127.0.0.1:9000/database'
    end

    it "maps --tables to the taps table_filter option" do
      @db.stub!(:args).and_return(["sqlite://local.db"])
      @db.stub!(:options).and_return(:tables => "tags,countries")
      opts = @db.send(:parse_taps_opts)
      opts[:table_filter].should == "(^tags$|^countries$)"
    end

    it "handles both a url and a --confirm on the command line" do
      @db.stub!(:args).and_return(["mysql://user:pass@host/db"])
      @db.stub!(:options).and_return(:confirm => "myapp")
      opts = { :database_url => 'mysql://user:pass@host/db', :default_chunksize => 1000, :indexes_first => true }
      @db.should_receive(:taps_client).with(:pull, opts)
      @db.pull
    end

    it "handles no url and --confirm on the command line" do
      @db.stub!(:options).and_return(:confirm => "myapp")
      opts = { :database_url => 'mysql://user:pass@host/db', :default_chunksize => 1000, :indexes_first => true }
      @db.should_receive(:parse_database_yml).and_return("mysql://user:pass@host/db")
      @db.should_receive(:taps_client).with(:pull, opts)
      @db.pull
    end

    it "works with a file-based url" do
      url = "sqlite://tmp/foo.db"
      @db.stub(:args).and_return([url])
      @db.stub(:options).and_return(:confirm => "myapp")
      @db.should_receive(:taps_client).with(:pull, hash_including(:database_url => url))
      @db.pull
    end

    describe "with erb in the database.yml" do
      before do
        @rails_env = ENV["RAILS_ENV"]
        ENV["RAILS_ENV"] = "development"

        FakeFS.activate!
        FileUtils.mkdir_p "config"
        File.open("config/database.yml", "w") do |file|
          file.puts <<-YAML
            development:
              adapter: db
              host: localhost
              database: <%= 'db'+'1' %>
          YAML
        end
      end

      after do
        FakeFS.deactivate!
        ENV["RAILS_ENV"] = @rails_env
      end

      it "handles ERB code in YAML" do
        @db.send(:parse_database_yml).should == 'db://localhost/db1?encoding=utf8'
      end
    end
  end
end
