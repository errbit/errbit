require 'spec_helper'
require 'heroku/pg_resolver'

include PGResolver

describe Resolver do
  context 'passed in a postgres:// url' do
    let(:url) { "postgres://uSer:pAss@ec2-whATEver.com/daTABAse" }
    let(:r) { Resolver.new url, "HEROKU_POSTGRESQL_SOME_URL" => 'not_that_db'}

    it { r[:name].should == 'Database on ec2-whATEver.com' }

    it "preserves case of the url" do
      r[:url].should == url
      url.upcase.should_not == url
    end
  end

  context "pass in *_URL" do
    let(:r) { Resolver.new "HEROKU_POSTGRESQL_SOME_URL", "HEROKU_POSTGRESQL_SOME_URL" => 'something'}

    it 'should warn to not add in _URL, and proceed without it' do
      r.message.should == "HEROKU_POSTGRESQL_SOME_URL is deprecated, please use HEROKU_POSTGRESQL_SOME"
    end

    it 'should have [] access' do
      r[:url].should == 'something'
      r[:name].should == 'HEROKU_POSTGRESQL_SOME'
    end
  end

  context "only shared database" do
     let(:config) do
       { 'DATABASE_URL'        => 'postgres://shared',
         'SHARED_DATABASE_URL' => 'postgres://shared' }
    end

    it 'returns the shared url when asked for DATABASE' do
      r = Resolver.new("DATABASE", config)
      r.url.should == 'postgres://shared'
      r.message.should_not be
    end

    it 'reutrns the shared url when asked for SHARED_DATABASE' do
      r = Resolver.new("SHARED_DATABASE", config)
      r.url.should == 'postgres://shared'
      r.message.should_not be
    end
  end

  context 'only yobuko database' do
    let(:config) do
       { 'DATABASE_URL'        => 'postgres://yobuko',
         'HEROKU_SHARED_POSTGRESQL_BLACK_URL' => 'postgres://yobuko' }
    end

    it 'returns the yobuko url when asked for DATABASE' do
      r = Resolver.new("DATABASE", config)
      r.url.should == 'postgres://yobuko'
      r.message.should_not be
    end

    it 'returns the yobuko url when asked for HEROKU_SHARED_POSTGRESQL' do
      r = Resolver.new("HEROKU_SHARED_POSTGRESQL_BLACK", config)
      r.url.should == 'postgres://yobuko'
      r.message.should_not be
    end
  end

  context 'only dedicated database' do
    let(:config) do
      { 'DATABASE_URL' => 'postgres://dedicated',
        'HEROKU_POSTGRESQL_PERIWINKLE_URL' => 'postgres://dedicated' }
    end

    it 'returns the dedicated url when asked for DATABASE' do
      r = Resolver.new('DATABASE', config)
      r.url.should == 'postgres://dedicated'
      r.message.should_not be
    end

    it 'works when asked for just COLOR' do
      r = Resolver.new('PERIWINKLE', config)
      r.url.should == 'postgres://dedicated'
      r.message.should_not be
    end

    it 'works when asked for just lowercase color' do
      r = Resolver.new('periwinkle', config)
      r.url.should == 'postgres://dedicated'
      r.message.should_not be
    end

    it 'returns the dedicated url when asked for H_PG_COLOR' do
      r = Resolver.new('HEROKU_POSTGRESQL_PERIWINKLE', config)
      r.url.should == 'postgres://dedicated'
      r.message.should_not be
    end

    it 'returns the dedicated url when asked for H_PG_COLOR_URL' do
      r = Resolver.new('HEROKU_POSTGRESQL_PERIWINKLE_URL', config)
      r.url.should == 'postgres://dedicated'
      r.message.should =~ /deprecated/
    end
  end

  context 'dedicated databases, yobuko and shared database' do
    let(:config) do
      { 'DATABASE_URL' => 'postgres://red',
        'SHARED_DATABASE_URL' => 'postgres://shared',
        'HEROKU_SHARED_POSTGRESQL_BLACK_URL' => 'postgres://yobuko',
        'HEROKU_POSTGRESQL_PERIWINKLE_URL' => 'postgres://pari',
        'HEROKU_POSTGRESQL_RED_URL' => 'postgres://red' }
    end

    it 'maps default correctly' do
      r = Resolver.new('DATABASE', config)
      r.url.should == 'postgres://red'
    end

    it 'warns if DATABASE_URL is wrong' do
      r = Resolver.new('DATABASE', config.merge!({"DATABASE_URL" => "foo"}))
      r.message.should =~ /DATABASE_URL does not match/
    end

    it 'is able to get the non default database' do
      r = Resolver.new('HEROKU_POSTGRESQL_PERIWINKLE', config)
      r.url.should == 'postgres://pari'
    end

    it 'is able to get the yobuko config var' do
      r = Resolver.new('HEROKU_SHARED_POSTGRESQL_BLACK', config)
      r.url.should == 'postgres://yobuko'
    end

    it 'returns all with Resolver.all' do
      Resolver.all(config).should =~ [
        {:name => 'SHARED_DATABASE',              :pretty_name => 'SHARED_DATABASE',                      :url => 'postgres://shared', :default => false},
        {:name => 'HEROKU_SHARED_POSTGRESQL_BLACK',:pretty_name =>'HEROKU_SHARED_POSTGRESQL_BLACK',      :url => 'postgres://yobuko', :default => false},
        {:name => 'HEROKU_POSTGRESQL_PERIWINKLE', :pretty_name => 'HEROKU_POSTGRESQL_PERIWINKLE',         :url => 'postgres://pari',   :default => false},
        {:name => 'HEROKU_POSTGRESQL_RED',        :pretty_name => 'HEROKU_POSTGRESQL_RED (DATABASE_URL)', :url => 'postgres://red',    :default => true}
      ]
    end
  end

  context "dev mode feature" do
    it 'allows an alternate addon prefix to be specified via env HEROKU_POSTGRESQL_ADDON_PREFIX' do
      old_env = ENV["HEROKU_POSTGRESQL_ADDON_PREFIX"]
      ENV["HEROKU_POSTGRESQL_ADDON_PREFIX"] = "SHOGUN_STAGING"
      config = { 'DATABASE_URL' => 'postgres://red',
                 'SHARED_DATABASE_URL' => 'postgres://shared',
                 'HEROKU_POSTGRESQL_PERIWINKLE_URL' => 'postgres://pari',
                 'SHOGUN_STAGING_RED_URL' => 'postgres://red' }
      r = Resolver.new('SHOGUN_STAGING_RED', config)
      r.url.should == 'postgres://red'
      ENV["HEROKU_POSTGRESQL_ADDON_PREFIX"] = old_env
    end
  end
end
