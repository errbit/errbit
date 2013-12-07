require 'spec_helper'

describe DataMigration do
  #FIXME @realmyst: отрефакторить, заюзать сиквенсы, тесты сделать максимально атомарными
  before do
    load File.join(Rails.root, 'spec/fixtures/mongodb_data_for_export.rb')
    @apps = MongodbDataStubs.apps
    @users = MongodbDataStubs.users
    db_name = "test_db"
    MongoClient.should_receive(:new).and_return(MongodbDataStubs.db(db_name))
    @migrator = DataMigration.new({:database => db_name})
  end

  describe "migrate users" do
    before do
      @migrator.copy_users
      @mongo_user = @users.last
      @pg_user = User.last
    end

    it "should copy users" do
      @pg_user.should_not be_nil
    end

    it "should save user mapping" do
      mapping = @migrator.user_mapping
      mapping[@mongo_user["_id"]].should == @pg_user.id
    end

    User.columns.each do |column|
      it "should correct copy value for '#{column.name}'" do
        @pg_user.read_attribute(column.name).should == @mongo_user[column.name] if @mongo_user.has_key?(column.name)
      end
    end
  end

  describe "migrate apps" do
    before do
      @migrator.copy_users
      @migrator.copy_apps
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
          if watcher["email"]
            @pg_app.watchers.find_by_email(watcher["email"]).should_not be_nil
          end
        end
      end

      it "should copy all accounts" do
        @mongo_app["watchers"].each do |watcher|
          if watcher["user_id"]
            user_id = @migrator.user_mapping[watcher["user_id"]]
            @pg_app.watchers.find_by_user_id(user_id).should_not be_nil
          end
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

    describe "migrate problems" do
      before do
        problems = MongodbDataStubs.problems
        @mongo_problem = problems.last
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

      describe "migrate comments" do
        before do
          comments = MongodbDataStubs.comments
          @mongo_comment = comments.last
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
          user_id = @migrator.user_mapping[@mongo_comment["user_id"]]
          pg_user = User.find(user_id)
          @pg_comment.user.should == pg_user
        end

      end

      describe "migrate errs" do
        before do
          @errs = MongodbDataStubs.errs
          @mongo_err = @errs.last
          @pg_err = @pg_problem.errs.last
        end

        it "should copy errs" do
          @pg_problem.errs.count.should == @errs.count
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

        describe "migrate notices" do
          before do
            @notices = MongodbDataStubs.notices
            @mongo_notice = @notices.last
            @pg_notice = @pg_err.notices.last
          end

          it "should copy errs" do
            @pg_err.notices.count.should == @notices.count
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

          describe "migrate backtrace" do
            before do
              @backtraces = MongodbDataStubs.backtraces
              @mongo_backtrace = @backtraces.last
              @pg_backtrace = @pg_notice.backtrace
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

        end
      end

    end
  end
end
