require 'spec_helper'

describe Deploy do
  
  context 'validations' do
    it 'requires a username' do
      deploy = Factory.build(:deploy, :username => nil)
      deploy.should_not be_valid
      deploy.errors[:username].should include("can't be blank")
    end
    
    it 'requires an environment' do
      deploy = Factory.build(:deploy, :environment => nil)
      deploy.should_not be_valid
      deploy.errors[:environment].should include("can't be blank")
    end
  end
  
end
