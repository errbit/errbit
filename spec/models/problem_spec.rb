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
    it 'returns the message from the first notice' do
      err = Factory(:err)
      notice1 = Factory(:notice, :err => err, :message => 'ERR 1')
      notice2 = Factory(:notice, :err => err, :message => 'ERR 2')
      err.problem.message.should == notice1.message
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
    
    # it "should throw an err if it's not successful" do
    #   problem = Factory(:problem)
    #   problem.should_not be_resolved
    #   problem.klass = nil
    #   problem.should_not be_valid
    #   lambda {
    #     problem.resolve!
    #   }.should raise_error(Mongoid::Errors::Validations)
    # end
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
    it "collects the Errs from several problems into one and deletes the other problems" do
      problem1 = Factory(:err).problem
      problem2 = Factory(:err).problem
      merged_problem = Problem.merge!(problem1, problem2)
      merged_problem.errs.length.should == 2
      
      lambda {
        problems = merged_problem.unmerge!
        problems.length.should == 2
        merged_problem.reload.errs.length.should == 1
      }.should change(Problem, :count).by(1)
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
  
  
end
