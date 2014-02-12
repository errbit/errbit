require 'spec_helper'

describe Problem do

  context 'validations' do
    it 'requires an environment' do
      err = Fabricate.build(:problem, :environment => nil)
      expect(err).to_not be_valid
      expect(err.errors[:environment]).to include("can't be blank")
    end
  end

  describe "Fabrication" do
    context "Fabricate(:problem)" do
      it 'should have no comment' do
        expect{
          Fabricate(:problem)
        }.to_not change(Comment, :count)
      end
    end

    context "Fabricate(:problem_with_comments)" do
      it 'should have 3 comments' do
        expect{
          Fabricate(:problem_with_comments)
        }.to change(Comment, :count).by(3)
      end
    end

    context "Fabricate(:problem_with_errs)" do
      it 'should have 3 errs' do
        expect{
          Fabricate(:problem_with_errs)
        }.to change(Err, :count).by(3)
      end
    end
  end

  context '#last_notice_at' do
    it "returns the created_at timestamp of the latest notice" do
      err = Fabricate(:err)
      problem = err.problem
      expect(problem).to_not be_nil

      notice1 = Fabricate(:notice, :err => err)
      expect(problem.last_notice_at).to eq notice1.created_at

      notice2 = Fabricate(:notice, :err => err)
      expect(problem.last_notice_at).to eq notice2.created_at
    end
  end

  context '#first_notice_at' do
    it "returns the created_at timestamp of the first notice" do
      err = Fabricate(:err)
      problem = err.problem
      expect(problem).to_not be_nil

      notice1 = Fabricate(:notice, :err => err)
      expect(problem.first_notice_at.to_i).to be_within(1).of(notice1.created_at.to_i)

      notice2 = Fabricate(:notice, :err => err)
      expect(problem.first_notice_at.to_i).to be_within(1).of(notice1.created_at.to_i)
    end
  end

  context '#message' do
    it "adding a notice caches its message" do
      err = Fabricate(:err)
      problem = err.problem
      expect {
        Fabricate(:notice, :err => err, :message => 'ERR 1')
      }.to change(problem, :message).from(nil).to('ERR 1')
    end
  end

  context 'being created' do
    context 'when the app has err notifications set to false' do
      it 'should not send an email notification' do
        app = Fabricate(:app_with_watcher, :notify_on_errs => false)
        expect(Mailer).to_not receive(:err_notification)
        Fabricate(:problem, :app => app)
      end
    end
  end

  context "#resolved?" do
    it "should start out as unresolved" do
      problem = Problem.new
      expect(problem).to_not be_resolved
      expect(problem).to be_unresolved
    end

    it "should be able to be resolved" do
      problem = Fabricate(:problem)
      expect(problem).to_not be_resolved
      problem.resolve!
      expect(problem.reload).to be_resolved
    end
  end

  context "resolve!" do
    it "marks the problem as resolved" do
      problem = Fabricate(:problem)
      expect(problem).to_not be_resolved
      problem.resolve!
      expect(problem).to be_resolved
    end

    it "should record the time when it was resolved" do
      problem = Fabricate(:problem)
      expected_resolved_at = Time.zone.now
      Timecop.freeze(expected_resolved_at) do
        problem.resolve!
      end
      expect(problem.resolved_at.to_s).to eq expected_resolved_at.to_s
    end

    it "should not reset notice count" do
      problem = Fabricate(:problem, :notices_count => 1)
      original_notices_count = problem.notices_count
      expect(original_notices_count).to be > 0

      problem.resolve!
      expect(problem.notices_count).to eq original_notices_count
    end

    it "should throw an err if it's not successful" do
      problem = Fabricate(:problem)
      expect(problem).to_not be_resolved
      problem.stub(:valid?).and_return(false)
      ## update_attributes not test #valid? but #errors.any?
      # https://github.com/mongoid/mongoid/blob/master/lib/mongoid/persistence.rb#L137
      er = ActiveModel::Errors.new(problem)
      er.add_on_blank(:resolved)
      problem.stub(:errors).and_return(er)
      expect(problem).to_not be_valid
      expect {
        problem.resolve!
      }.to raise_error(Mongoid::Errors::Validations)
    end
  end

  context "#unmerge!" do
    it "creates a separate problem for each err" do
      problem1 = Fabricate(:notice).problem
      problem2 = Fabricate(:notice).problem
      merged_problem = Problem.merge!(problem1, problem2)
      expect(merged_problem.errs.length).to eq 2

      expect { merged_problem.unmerge! }.to change(Problem, :count).by(1)
      expect(merged_problem.errs(true).length).to eq 1
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
        expect(Problem.resolved.all).to include(resolved)
        expect(Problem.resolved.all).to_not include(unresolved)
      end
    end

    context "unresolved" do
      it 'only finds unresolved Problems' do
        resolved = Fabricate(:problem, :resolved => true)
        unresolved = Fabricate(:problem, :resolved => false)
        expect(Problem.unresolved.all).to_not include(resolved)
        expect(Problem.unresolved.all).to include(unresolved)
      end
    end

    context "searching" do
      it 'finds the correct record' do
        find = Fabricate(:problem, :resolved => false, :error_class => 'theErrorclass::other',
                         :message => "other", :where => 'errorclass', :environment => 'development', :app_name => 'other')
        dont_find = Fabricate(:problem, :resolved => false, :error_class => "Batman",
                              :message => 'todo', :where => 'classerror', :environment => 'development', :app_name => 'other')
        expect(Problem.search("theErrorClass").unresolved).to include(find)
        expect(Problem.search("theErrorClass").unresolved).to_not include(dont_find)
      end
      it 'find on where message' do
        problem = Fabricate(:problem, :where => 'cyril')
        expect(Problem.search('cyril').entries).to eq [problem]
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
      expect(@problem.notices_count).to eq 0
    end

    it "adding a notice increases #notices_count by 1" do
      expect {
        Fabricate(:notice, :err => @err, :message => 'ERR 1')
      }.to change(@problem.reload, :notices_count).from(0).to(1)
    end

    it "removing a notice decreases #notices_count by 1" do
      notice1 = Fabricate(:notice, :err => @err, :message => 'ERR 1')
      expect {
        @err.notices.first.destroy
        @problem.reload
      }.to change(@problem, :notices_count).from(1).to(0)
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
      expect {
        app.update_attributes!(:name => "Bar App")
        problem.reload
      }.to change(problem, :app_name).to("Bar App")
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
      expect {
        @deploy = Fabricate(:deploy, :app => @app, :created_at => next_deploy)
        problem.reload
      }.to change(problem, :last_deploy_at).from(@last_deploy).to(next_deploy)
    end
  end

  context "notice messages cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, :app => @app)
      @err = Fabricate(:err, :problem => @problem)
    end

    it "#messages should be empty by default" do
      expect(@problem.messages).to eq ({})
    end

    it "adding a notice adds a string to #messages" do
      expect {
        Fabricate(:notice, :err => @err, :message => 'ERR 1')
      }.to change(@problem, :messages).from({}).to({Digest::MD5.hexdigest('ERR 1') => {'value' => 'ERR 1', 'count' => 1}})
    end

    it "removing a notice removes string from #messages" do
      notice1 = Fabricate(:notice, :err => @err, :message => 'ERR 1')
      expect {
        @err.notices.first.destroy
        @problem.reload
      }.to change(@problem, :messages).from({Digest::MD5.hexdigest('ERR 1') => {'value' => 'ERR 1', 'count' => 1}}).to({})
    end

    it "removing a notice from the problem with broken counter should not raise an error" do
      notice1 = Fabricate(:notice, :err => @err, :message => 'ERR 1')
      @problem.messages = {}
      @problem.save!
      expect {@err.notices.first.destroy}.not_to raise_error
    end
  end

  context "notice hosts cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, :app => @app)
      @err = Fabricate(:err, :problem => @problem)
    end

    it "#hosts should be empty by default" do
      expect(@problem.hosts).to eq ({})
    end

    it "adding a notice adds a string to #hosts" do
      expect {
        Fabricate(:notice, :err => @err, :request => {'url' => "http://example.com/resource/12"})
      }.to change(@problem, :hosts).from({}).to({Digest::MD5.hexdigest('example.com') => {'value' => 'example.com', 'count' => 1}})
    end

    it "removing a notice removes string from #hosts" do
      notice1 = Fabricate(:notice, :err => @err, :request => {'url' => "http://example.com/resource/12"})
      expect {
        @err.notices.first.destroy
        @problem.reload
      }.to change(@problem, :hosts).from({Digest::MD5.hexdigest('example.com') => {'value' => 'example.com', 'count' => 1}}).to({})
    end
  end

  context "notice user_agents cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, :app => @app)
      @err = Fabricate(:err, :problem => @problem)
    end

    it "#user_agents should be empty by default" do
      expect(@problem.user_agents).to eq ({})
    end

    it "adding a notice adds a string to #user_agents" do
      expect {
        Fabricate(:notice, :err => @err, :request => {'cgi-data' => {'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16'}})
      }.to change(@problem, :user_agents).from({}).to({Digest::MD5.hexdigest('Chrome 10.0.648.204 (OS X 10.6.7)') => {'value' => 'Chrome 10.0.648.204 (OS X 10.6.7)', 'count' => 1}})
    end

    it "removing a notice removes string from #user_agents" do
      notice1 = Fabricate(:notice, :err => @err, :request => {'cgi-data' => {'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16'}})
      expect {
        @err.notices.first.destroy
        @problem.reload
      }.to change(@problem, :user_agents).from({
        Digest::MD5.hexdigest('Chrome 10.0.648.204 (OS X 10.6.7)') => {'value' => 'Chrome 10.0.648.204 (OS X 10.6.7)', 'count' => 1}
      }).to({})
    end
  end

  context "comment counter cache" do
    before do
      @app = Fabricate(:app)
      @problem = Fabricate(:problem, :app => @app)
    end

    it "#comments_count returns 0 by default" do
      expect(@problem.comments_count).to eq 0
    end

    it "adding a comment increases #comments_count by 1" do
      expect {
        Fabricate(:comment, :err => @problem)
      }.to change(@problem, :comments_count).from(0).to(1)
    end

    it "removing a comment decreases #comments_count by 1" do
      comment1 = Fabricate(:comment, :err => @problem)
      expect {
        @problem.reload.comments.first.destroy
        @problem.reload
      }.to change(@problem, :comments_count).from(1).to(0)
    end
  end


end

