require 'spec_helper'

describe Project do
  
  context 'validations' do
    it 'requires a name' do
      project = Factory.build(:project, :name => nil)
      project.should_not be_valid
      project.errors[:name].should include("can't be blank")
    end
    
    it 'requires unique names' do
      Factory(:project, :name => 'Hypnotoad')
      project = Factory.build(:project, :name => 'Hypnotoad')
      project.should_not be_valid
      project.errors[:name].should include('is already taken')
    end
    
    it 'requires unique api_keys' do
      Factory(:project, :api_key => 'APIKEY')
      project = Factory.build(:project, :api_key => 'APIKEY')
      project.should_not be_valid
      project.errors[:api_key].should include('is already taken')
    end
  end
  
  context 'being created' do
    it 'generates a new api-key' do
      project = Factory.build(:project)
      project.api_key.should be_nil
      project.save
      project.api_key.should_not be_nil
    end
    
    it 'generates a correct api-key' do
      project = Factory(:project)
      project.api_key.should match(/^[a-f0-9]{32}$/)
    end
  end
  
end
