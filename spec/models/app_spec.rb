require 'spec_helper'

describe App do
  
  
  context 'validations' do
    it 'requires a name' do
      app = Factory.build(:app, :name => nil)
      app.should_not be_valid
      app.errors[:name].should include("can't be blank")
    end
    
    it 'requires unique names' do
      Factory(:app, :name => 'Errbit')
      app = Factory.build(:app, :name => 'Errbit')
      app.should_not be_valid
      app.errors[:name].should include('is already taken')
    end
    
    it 'requires unique api_keys' do
      Factory(:app, :api_key => 'APIKEY')
      app = Factory.build(:app, :api_key => 'APIKEY')
      app.should_not be_valid
      app.errors[:api_key].should include('is already taken')
    end
  end
  
  
  context 'being created' do
    it 'generates a new api-key' do
      app = Factory.build(:app)
      app.api_key.should be_nil
      app.save
      app.api_key.should_not be_nil
    end
    
    it 'generates a correct api-key' do
      app = Factory(:app)
      app.api_key.should match(/^[a-f0-9]{32}$/)
    end
  end
  
  
  context '#find_or_create_err!' do
    before do
      @app = Factory(:app)
      @conditions = {
        :klass        => 'Whoops',
        :component    => 'Foo',
        :action       => 'bar',
        :environment  => 'production'
      }
    end
    
    it 'returns the correct err if one already exists' do
      existing = Factory(:err, @conditions.merge(:problem => Factory(:problem, :app => @app)))
      @app.find_err(@conditions).should == existing
      @app.find_or_create_err!(@conditions).should == existing
    end
    
    it 'assigns the returned err to the given app' do
      @app.find_or_create_err!(@conditions).app.should == @app
    end
    
    it 'creates a new problem if a matching one does not already exist' do
      @app.find_err(@conditions).should be_nil
      lambda {
        @app.find_or_create_err!(@conditions)
      }.should change(Problem,:count).by(1)
    end
  end
  
  
end
