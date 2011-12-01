require 'spec_helper'

describe Problem do
  describe "Fabrication" do
    context "Fabricate(:problem)" do
      it 'should be valid' do
        Fabricate.build(:problem).should be_valid
      end
      it 'should have no comment' do
        lambda do
          Fabricate(:problem)
        end.should_not change(Comment, :count)
      end
    end

    context "Fabricate(:problem_with_comments)" do
      it 'should be valid' do
        Fabricate.build(:problem_with_comments).should be_valid
      end
      it 'should have 3 comments' do
        lambda do
          Fabricate(:problem_with_comments)
        end.should change(Comment, :count).by(3)
      end
    end
  end
  context '#last_notice_at' do
    it "returns the created_at timestamp of the latest notice" do
      err = Fabricate(:err)
      problem = err.problem
      problem.should_not be_nil

      problem.last_notice_at.should be_nil

      notice1 = Fabricate(:notice, :err => err)
      problem.last_notice_at.should == notice1.created_at

      notice2 = Fabricate(:notice, :err => err)
      problem.last_notice_at.should == notice2.created_at
    end
  end


  context '#message' do
    it "adding a notice caches its message" do
      err = Fabricate(:err)
      problem = err.problem
      lambda {
        Fabricate(:notice, :err => err, :message => 'ERR 1')
      }.should change(problem, :message).from(nil).to('ERR 1')
    end
  end


  context 'being created' do
    context 'when the app has err notifications set to false' do
      it 'should not send an email notification' do
        app = Fabricate(:app_with_watcher, :notify_on_errs => false)
        Mailer.should_not_receive(:err_notification)
        Fabricate(:problem, :app => app)
      end
    end
  end


  context "#resolved?" do
    it "should start out as unresolved" do
      problem = Problem.new
      problem.should_not be_resolved
      problem.should be_unresolved
    end

    it "should be able to be resolved" do
      problem = Fabricate(:problem)
      problem.should_not be_resolved
      problem.resolve!
      problem.reload.should be_resolved
    end
  end


  context "resolve!" do
    it "marks the problem as resolved" do
      problem = Fabricate(:problem)
      problem.should_not be_resolved
      problem.resolve!
      problem.should be_resolved
    end

    it "should throw an err if it's not successful" do
      problem = Fabricate(:problem)
      problem.should_not be_resolved
      problem.stub!(:valid?).and_return(false)
      ## update_attributes not test #valid? but #errors.any?
      # https://github.com/mongoid/mongoid/blob/master/lib/mongoid/persistence.rb#L137
      er = ActiveModel::Errors.new(problem)
      er.add_on_blank(:resolved)
      problem.stub!(:errors).and_return(er)
      problem.should_not be_valid
      lambda {
        problem.resolve!
      }.should raise_error(Mongoid::Errors::Validations)
    end
  end


  context ".merge!" do
    it "collects the Errs from several problems into one and deletes the other problems" do
      problem1 = Fabricate(:err).problem
      problem2 = Fabricate(:err).problem
      problem1.errs.length.should == 1
      problem2.errs.length.should == 1

      lambda {
        merged_problem = Problem.merge!(problem1, problem2)
        merged_problem.reload.errs.length.should == 2
      }.should change(Problem, :count).by(-1)
    end
  end


  context "#unmerge!" do
    it "creates a separate problem for each err" do
      problem1 = Fabricate(:notice).problem
      problem2 = Fabricate(:notice).problem
      merged_problem = Problem.merge!(problem1, problem2)
      merged_problem.errs.length.should == 2

      expect { merged_problem.unmerge! }.to change(Problem, :count).by(1)
      merged_problem.errs(true).length.should == 1
    end

    it "runs smoothly for problem without errs" do
      expect { Fabricate(:problem).unmerge! }.not_to raise_error
    end
  end


  context "Scopes" do
    context "resolved" do
      it 'only finds resolved Problems' do
        resolved = Fabricate(:problem, :resolved => true)
        unresolved = Fabricate(:problem, :resolved => false)
        Problem.resolved.all.should include(resolved)
        Problem.resolved.all.should_not include(unresolved)
      end
    end

    context "unresolved" do
      it 'only finds unresolved Problems' do
        resolved = Fabricate(:problem, :resolved => true)
        unresolved = Fabricate(:problem, :resolved => false)
        Problem.unresolved.all.should_not include(resolved)
        Problem.unresolved.all.should include(unresolved)
      end
    end
  end


  context "notice counter cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, :app => @app)
      @err = Fabricate(:err, :problem => @problem)
    end

    it "#notices_count returns 0 by default" do
      @problem.notices_count.should == 0
    end

    it "adding a notice increases #notices_count by 1" do
      lambda {
        Fabricate(:notice, :err => @err, :message => 'ERR 1')
      }.should change(@problem, :notices_count).from(0).to(1)
    end

    it "removing a notice decreases #notices_count by 1" do
      notice1 = Fabricate(:notice, :err => @err, :message => 'ERR 1')
      lambda {
        @err.notices.first.destroy
        @problem.reload
      }.should change(@problem, :notices_count).from(1).to(0)
    end
  end


  context "#app_name" do
    let!(:app) { Fabricate(:app) }
    let!(:problem) { Fabricate(:problem, :app => app) }

    before { app.reload }

    it "is set when a problem is created" do
      assert_equal app.name, problem.app_name
    end

    it "is updated when an app is updated" do
      lambda {
        app.update_attributes!(:name => "Bar App")
        problem.reload
      }.should change(problem, :app_name).to("Bar App")
    end
  end

  context "#last_deploy_at" do
    before do
      @app = Fabricate(:app)
      @last_deploy = Time.at(10.days.ago.localtime.to_i)
      deploy = Fabricate(:deploy, :app => @app, :created_at => @last_deploy, :environment => "production")
    end

    it "is set when a problem is created" do
      problem = Fabricate(:problem, :app => @app, :environment => "production")
      assert_equal @last_deploy, problem.last_deploy_at
    end

    it "is updated when a deploy is created" do
      problem = Fabricate(:problem, :app => @app, :environment => "production")
      next_deploy = Time.at(5.minutes.ago.localtime.to_i)
      lambda {
        @deploy = Fabricate(:deploy, :app => @app, :created_at => next_deploy)
        problem.reload
      }.should change(problem, :last_deploy_at).from(@last_deploy).to(next_deploy)
    end
  end

  context "notice messages cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, :app => @app)
      @err = Fabricate(:err, :problem => @problem)
    end

    it "#messages should be empty by default" do
      @problem.messages.should == {}
    end

    it "adding a notice adds a string to #messages" do
      lambda {
        Fabricate(:notice, :err => @err, :message => 'ERR 1')
      }.should change(@problem, :messages).from({}).to({Digest::MD5.hexdigest('ERR 1') => {'value' => 'ERR 1', 'count' => 1}})
    end

    it "removing a notice removes string from #messages" do
      notice1 = Fabricate(:notice, :err => @err, :message => 'ERR 1')
      lambda {
        @err.notices.first.destroy
        @problem.reload
      }.should change(@problem, :messages).from({Digest::MD5.hexdigest('ERR 1') => {'value' => 'ERR 1', 'count' => 1}}).to({})
    end
  end

  context "notice hosts cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, :app => @app)
      @err = Fabricate(:err, :problem => @problem)
    end

    it "#hosts should be empty by default" do
      @problem.hosts.should == {}
    end

    it "adding a notice adds a string to #hosts" do
      lambda {
        Fabricate(:notice, :err => @err, :request => {'url' => "http://example.com/resource/12"})
      }.should change(@problem, :hosts).from({}).to({Digest::MD5.hexdigest('example.com') => {'value' => 'example.com', 'count' => 1}})
    end

    it "removing a notice removes string from #hosts" do
      notice1 = Fabricate(:notice, :err => @err, :request => {'url' => "http://example.com/resource/12"})
      lambda {
        @err.notices.first.destroy
        @problem.reload
      }.should change(@problem, :hosts).from({Digest::MD5.hexdigest('example.com') => {'value' => 'example.com', 'count' => 1}}).to({})
    end
  end

  context "notice user_agents cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, :app => @app)
      @err = Fabricate(:err, :problem => @problem)
    end

    it "#user_agents should be empty by default" do
      @problem.user_agents.should == {}
    end

    it "adding a notice adds a string to #user_agents" do
      lambda {
        Fabricate(:notice, :err => @err, :request => {'cgi-data' => {'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16'}})
      }.should change(@problem, :user_agents).from({}).to({Digest::MD5.hexdigest('Chrome 10.0.648.204') => {'value' => 'Chrome 10.0.648.204', 'count' => 1}})
    end

    it "removing a notice removes string from #user_agents" do
      notice1 = Fabricate(:notice, :err => @err, :request => {'cgi-data' => {'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16'}})
      lambda {
        @err.notices.first.destroy
        @problem.reload
      }.should change(@problem, :user_agents).from({Digest::MD5.hexdigest('Chrome 10.0.648.204') => {'value' => 'Chrome 10.0.648.204', 'count' => 1}}).to({})
    end
  end

  context "comment counter cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, :app => @app)
    end

    it "#comments_count returns 0 by default" do
      @problem.comments_count.should == 0
    end

    it "adding a comment increases #comments_count by 1" do
      lambda {
        Fabricate(:comment, :err => @problem)
      }.should change(@problem, :comments_count).from(0).to(1)
    end

    it "removing a comment decreases #comments_count by 1" do
      comment1 = Fabricate(:comment, :err => @problem)
      lambda {
        @problem.reload.comments.first.destroy
        @problem.reload
      }.should change(@problem, :comments_count).from(1).to(0)
    end
  end


end

