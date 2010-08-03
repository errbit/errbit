require 'spec_helper'

describe Error do
  
  context 'validations' do
    it 'requires a klass' do
      error = Factory.build(:error, :klass => nil)
      error.should_not be_valid
      error.errors[:klass].should include("can't be blank")
    end
    
    it 'requires an environment' do
      error = Factory.build(:error, :environment => nil)
      error.should_not be_valid
      error.errors[:environment].should include("can't be blank")
    end
  end
  
  context '#for' do
    before do
      @conditions = {
        :klass        => 'Whoops',
        :message      => 'Whoops: Oopsy Daisy',
        :component    => 'Foo',
        :action       => 'bar',
        :environment  => 'production'
      }
    end
    
    it 'returns the correct error if one already exists' do
      existing = Error.create(@conditions)
      Error.for(@conditions).should == existing
    end
    
    it 'creates a new error if a matching one does not already exist' do
      Error.where(@conditions).exists?.should == false
      lambda {
        Error.for(@conditions)
      }.should change(Error,:count).by(1)
    end
  end
  
  context '#last_notice_at' do
    it "returns the created_at timestamp of the latest notice" do
      error = Factory(:error)
      error.last_notice_at.should be_nil
      
      notice1 = Factory(:notice, :error => error)
      error.last_notice_at.should == notice1.created_at
      
      notice2 = Factory(:notice, :error => error)
      error.last_notice_at.should == notice2.created_at
    end
  end
  
end