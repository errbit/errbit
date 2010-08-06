require 'spec_helper'

describe Err do
  
  context 'validations' do
    it 'requires a klass' do
      error = Factory.build(:err, :klass => nil)
      error.should_not be_valid
      error.errors[:klass].should include("can't be blank")
    end
    
    it 'requires an environment' do
      error = Factory.build(:err, :environment => nil)
      error.should_not be_valid
      error.errors[:environment].should include("can't be blank")
    end
  end
  
  context '#for' do
    before do
      @project = Factory(:project)
      @conditions = {
        :project      => @project,
        :klass        => 'Whoops',
        :component    => 'Foo',
        :action       => 'bar',
        :environment  => 'production'
      }
    end
    
    it 'returns the correct error if one already exists' do
      existing = Err.create(@conditions)
      Err.for(@conditions).should == existing
    end
    
    it 'assigns the returned error to the given project' do
      Err.for(@conditions).project.should == @project
    end
    
    it 'creates a new error if a matching one does not already exist' do
      Err.where(@conditions.except(:project)).exists?.should == false
      lambda {
        Err.for(@conditions)
      }.should change(Err,:count).by(1)
    end
  end
  
  context '#last_notice_at' do
    it "returns the created_at timestamp of the latest notice" do
      error = Factory(:err)
      error.last_notice_at.should be_nil
      
      notice1 = Factory(:notice, :err => error)
      error.last_notice_at.should == notice1.created_at
      
      notice2 = Factory(:notice, :err => error)
      error.last_notice_at.should == notice2.created_at
    end
  end
  
  context '#message' do
    it 'returns the message from the first notice' do
      err = Factory(:err)
      notice1 = Factory(:notice, :err => err, :message => 'ERR 1')
      notice2 = Factory(:notice, :err => err, :message => 'ERR 2')
      err.message.should == notice1.message
    end
  end
  
  context "#resolved?" do
    it "should start out as unresolved" do
      error = Err.new
      error.should_not be_resolved
      error.should be_unresolved
    end
    
    it "should be able to be resolved" do
      error = Factory(:err)
      error.should_not be_resolved
      error.resolve!
      error.reload.should be_resolved
    end
  end
  
  context "Scopes" do
    context "resolved" do
      it 'only finds resolved Errors' do
        resolved = Factory(:err, :resolved => true)
        unresolved = Factory(:err, :resolved => false)
        Err.resolved.all.should include(resolved)
        Err.resolved.all.should_not include(unresolved)
      end
    end
    
    context "unresolved" do
      it 'only finds unresolved Errors' do
        resolved = Factory(:err, :resolved => true)
        unresolved = Factory(:err, :resolved => false)
        Err.unresolved.all.should_not include(resolved)
        Err.unresolved.all.should include(unresolved)
      end
    end
  end
  
end