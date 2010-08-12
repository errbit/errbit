require 'spec_helper'

describe User do
  
  context 'validations' do
    it 'require that a name is present' do
      user = Factory.build(:user, :name => nil)
      user.should_not be_valid
      user.errors[:name].should include("can't be blank")
    end
  end
  
end
