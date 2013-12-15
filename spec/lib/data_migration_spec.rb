require 'spec_helper'

describe DataMigration do
  before do
    load File.join(Rails.root, 'spec/fixtures/mongodb_data_for_export.rb')
    @apps = MongodbDataStubs.apps
    @users = MongodbDataStubs.users
    db_name = "test_db"
    db = MongodbDataStubs.db(db_name)
    MongoClient.should_receive(:new).and_return(db)
    
    [:apps, :users, :problems, :comments, :errs, :notices, :backtraces].each do |collection|
      records = db[db_name][collection]
      records.stub(:name).and_return(collection)
      def records.find(*args)
        yield self if block_given?
        self
      end
      records.stub(:find_one).and_return(records.last)
    end
    
    @migrator = DataMigration::Worker.new({sessions: {default: {database: db_name}}})
    @migrator.prepare
  end
  
  after do
    @migrator.teardown
  end

  describe "migrate users" do
    before do
      @migrator.copy! :users
      @mongo_user = @users.last
      @pg_user = User.last
    end

    it "should copy users" do
      @pg_user.should_not be_nil
    end

    it "should keep track of each user's legacy id" do
      @pg_user.remote_id.should == @mongo_user["_id"].to_s
    end

    User.columns.each do |column|
      it "should correctly copy values for '#{column.name}'" do
        @pg_user.read_attribute(column.name).should == @mongo_user[column.name] if @mongo_user.has_key?(column.name)
      end
    end
  end

  describe "migrate apps" do
    before do
      @migrator.copy! :users
      @migrator.copy! :apps
      @mongo_app = @apps.last
      @pg_app = App.find_by_api_key(@mongo_app["api_key"])
    end

    it "should copy apps" do
      @pg_app.should_not be_nil
    end

    App.columns.each do |column|
      it "should correct copy value for '#{column.name}'" do
        @pg_app.read_attribute(column.name).should == @mongo_app[column.name] if @mongo_app.has_key?(column.name)
      end
    end

    it "should copy issue tracker" do
      @pg_app.issue_tracker.should_not be_nil
      @pg_app.issue_tracker.type.should == @mongo_app["issue_tracker"]["_type"]
    end

    it "should copy notification service" do
      @pg_app.notification_service.should_not be_nil
      @pg_app.notification_service.type.should == @mongo_app["notification_service"]["_type"]
    end

    describe "migrate watchers" do
      it "should copy watchers" do
        @pg_app.watchers.count.should == @mongo_app["watchers"].count
      end

      it "should copy all emails" do
        @mongo_app["watchers"].each do |watcher|
          next unless watcher["email"]
          
          @pg_app.watchers.find_by_email(watcher["email"]).should_not be_nil
        end
      end

      it "should copy all watchers' users" do
        @mongo_app["watchers"].each do |watcher|
          next unless watcher["user_id"]
          
          user = User.find_by_remote_id watcher["user_id"].to_s
          user.should_not be_nil
          @pg_app.watchers.find_by_user_id(user.id).should_not be_nil
        end
      end
    end

    describe "migrate deploys" do
      before do
        @mongo_deploy = @mongo_app["deploys"].last
        @pg_deploy = @pg_app.deploys.last
      end

      it "should copy deploys" do
        @pg_app.deploys.count.should == @mongo_app["deploys"].count
      end

      Deploy.columns.each do |column|
        it "should correct copy value for '#{column.name}'" do
          @pg_deploy.read_attribute(column.name).should == @mongo_deploy[column.name] if @mongo_deploy.has_key?(column.name)
        end
      end
    end
  end

  describe "migrate problems" do
    before do
      @migrator.copy! :users
      @migrator.copy! :apps
      @migrator.copy! :problems
      @migrator.copy! :errs
      @migrator.copy! :backtraces
      @migrator.copy! :notices # <-- because these mess with problems
      @mongo_problem = MongodbDataStubs.problems.last
      @pg_problem = Problem.last
    end

    it "should copy problem" do
      @pg_problem.should_not be_nil
    end

    Problem.columns.each do |column|
      next if column.name.in? ["id", "app_id"]
      it "should correct copy value for '#{column.name}'" do
        @pg_problem.read_attribute(column.name).should == @mongo_problem[column.name] if @mongo_problem.has_key?(column.name)
      end
    end
  end

  describe "migrate comments" do
    before do
      @migrator.copy! :users
      @migrator.copy! :apps
      @migrator.copy! :problems
      @migrator.copy! :comments
      @mongo_comment = MongodbDataStubs.comments.last
      @pg_problem = Problem.last
      @pg_comment = @pg_problem.comments.last
    end
  
    it "should copy comments" do
      @pg_comment.should_not be_nil
    end
  
    %w(created_at updated_at body).each do |column|
      it "should corrent copy value for '#{column}'" do
        @pg_comment.read_attribute(column).should == @mongo_comment[column]
      end
    end
  
    it "should correct link to problem" do
      @pg_comment.err.should == @pg_problem
    end
  
    it "should correct link to user" do
      user = User.find_by_remote_id @mongo_comment["user_id"].to_s
      user.should_not be_nil
      @pg_comment.user.should == user
    end
  end
  
  describe "migrate errs" do
    before do
      @migrator.copy! :users
      @migrator.copy! :apps
      @migrator.copy! :problems
      @migrator.copy! :errs
      @mongo_err = MongodbDataStubs.errs.last
      @pg_problem = Problem.last
      @pg_err = @pg_problem.errs.last
    end
  
    it "should copy errs" do
      Err.count.should == MongodbDataStubs.errs.count
    end
  
    Err.columns.each do |column|
      next if column.name.in? ["id", "problem_id"]
      it "should corrent copy value for '#{column.name}'" do
        @pg_err.read_attribute(column.name).should == @mongo_err[column.name] if @mongo_err.has_key?(column.name)
      end
    end
  
    it "should correct link to problem" do
      @pg_err.problem.should == @pg_problem
    end
  end

  describe "migrate backtrace" do
    before do
      @migrator.copy! :backtraces
      @backtraces = MongodbDataStubs.backtraces
      @mongo_backtrace = @backtraces.last
      @pg_backtrace = Backtrace.last
    end

    it "should copy backtrace" do
      @pg_backtrace.should_not be_nil
    end

    Backtrace.columns.each do |column|
      it "should corrent copy value for '#{column.name}'" do
        @pg_backtrace.read_attribute(column.name).should == @mongo_backtrace[column.name] if @mongo_backtrace.has_key?(column.name)
      end
    end

    it "should copy correct lines count" do
      @pg_backtrace.lines.count.should == @mongo_backtrace["lines"].count
    end
  end

  describe "migrate notices" do
    before do
      @migrator.copy! :users
      @migrator.copy! :apps
      @migrator.copy! :problems
      @migrator.copy! :errs
      @migrator.copy! :backtraces
      @migrator.copy! :notices
      @mongo_notice = MongodbDataStubs.notices.last
      @pg_problem = Problem.last
      @pg_err = @pg_problem.errs.last
      @pg_notice = @pg_err.notices.last
    end

    it "should copy errs" do
      Notice.count.should == MongodbDataStubs.notices.count
    end

    Notice.columns.each do |column|
      next if column.name.in? ["id", "err_id", "backtrace_id"]
      it "should corrent copy value for '#{column.name}'" do
        @pg_notice.read_attribute(column.name).should == @mongo_notice[column.name] if @mongo_notice.has_key?(column.name)
      end
    end

    it "should correct link to problem" do
      @pg_notice.err.should == @pg_err
    end
  end

end
