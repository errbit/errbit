require 'spec_helper'

describe Error do
  
  context '#for' do
    before do
      @conditions = {
        :class_name   => 'Whoops',
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
  
end