require 'spec_helper'

describe Problem do
  context '#last_notice_at' do
    it "returns the created_at timestamp of the latest notice" do
      err = Factory(:err)
      problem = err.problem
      problem.should_not be_nil

      problem.last_notice_at.should be_nil

      notice1 = Factory(:notice, :err => err)
      problem.last_notice_at.should == notice1.created_at

      notice2 = Factory(:notice, :err => err)
      problem.last_notice_at.should == notice2.created_at
    end
  end


  context '#message' do
    it "adding a notice caches its message" do
      err = Factory(:err)
      problem = err.problem
      lambda {
        Factory(:notice, :err => err, :message => 'ERR 1')
      }.should change(problem, :message).from(nil).to('ERR 1')
    end
  end


  context 'being created' do
    context 'when the app has err notifications set to false' do
      it 'should not send an email notification' do
        app = Factory(:app_with_watcher, :notify_on_errs => false)
        Mailer.should_not_receive(:err_notification)
        Factory(:problem, :app => app)
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
      problem = Factory(:problem)
      problem.should_not be_resolved
      problem.resolve!
      problem.reload.should be_resolved
    end
  end


  context "resolve!" do
    it "marks the problem as resolved" do
      problem = Factory(:problem)
      problem.should_not be_resolved
      problem.resolve!
      problem.should be_resolved
    end

    it "should throw an err if it's not successful" do
      problem = Factory(:problem)
      problem.should_not be_resolved
      problem.stub!(:valid?).and_return(false)
      problem.should_not be_valid
      lambda {
        problem.resolve!
      }.should raise_error(Mongoid::Errors::Validations)
    end
  end


  context ".merge!" do
    it "collects the Errs from several problems into one and deletes the other problems" do
      problem1 = Factory(:err).problem
      problem2 = Factory(:err).problem
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
      problem1 = Factory(:notice).problem
      problem2 = Factory(:notice).problem
      merged_problem = Problem.merge!(problem1, problem2)
      merged_problem.errs.length.should == 2

      expect { merged_problem.unmerge! }.to change(Problem, :count).by(1)
      merged_problem.errs(true).length.should == 1
    end

    it "runs smoothly for problem without errs" do
      expect { Factory(:problem).unmerge! }.not_to raise_error
    end
  end


  context "Scopes" do
    context "resolved" do
      it 'only finds resolved Problems' do
        resolved = Factory(:problem, :resolved => true)
        unresolved = Factory(:problem, :resolved => false)
        Problem.resolved.all.should include(resolved)
        Problem.resolved.all.should_not include(unresolved)
      end
    end

    context "unresolved" do
      it 'only finds unresolved Problems' do
        resolved = Factory(:problem, :resolved => true)
        unresolved = Factory(:problem, :resolved => false)
        Problem.unresolved.all.should_not include(resolved)
        Problem.unresolved.all.should include(unresolved)
      end
    end
  end


  context "notice counter cache" do
    before do
      @app = Factory(:app)
      @problem = Factory(:problem, :app => @app)
      @err = Factory(:err, :problem => @problem)
    end

    it "#notices_count returns 0 by default" do
      @problem.notices_count.should == 0
    end

    it "adding a notice increases #notices_count by 1" do
      lambda {
        Factory(:notice, :err => @err, :message => 'ERR 1')
      }.should change(@problem, :notices_count).from(0).to(1)
    end

    it "removing a notice decreases #notices_count by 1" do
      notice1 = Factory(:notice, :err => @err, :message => 'ERR 1')
      lambda {
        @err.notices.first.destroy
        @problem.reload
      }.should change(@problem, :notices_count).from(1).to(0)
    end
  end


  context "#app_name" do
    before do
      @app = Factory(:app)
    end

    it "is set when a problem is created" do
      problem = Factory(:problem, :app => @app)
      assert_equal @app.name, problem.app_name
    end

    it "is updated when an app is updated" do
      problem = Factory(:problem, :app => @app)
      lambda {
        @app.update_attributes!(:name => "Bar App")
        problem.reload
      }.should change(problem, :app_name).to("Bar App")
    end
  end


  context "#last_deploy_at" do
    before do
      @app = Factory(:app)
      @last_deploy = 10.days.ago.localtime.round(0)
      deploy = Factory(:deploy, :app => @app, :created_at => @last_deploy, :environment => "production")
    end

    it "is set when a problem is created" do
      problem = Factory(:problem, :app => @app, :environment => "production")
      assert_equal @last_deploy, problem.last_deploy_at
    end

    it "is updated when a deploy is created" do
      problem = Factory(:problem, :app => @app, :environment => "production")
      next_deploy = 5.minutes.ago.localtime.round(0)
      lambda {
        @deploy = Factory(:deploy, :app => @app, :created_at => next_deploy)
        problem.reload
      }.should change(problem, :last_deploy_at).from(@last_deploy).to(next_deploy)
    end
  end
end

