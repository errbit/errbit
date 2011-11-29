require 'spec_helper'

describe Err do

  context 'validations' do
    it 'requires a klass' do
      err = Fabricate.build(:err, :klass => nil)
      err.should_not be_valid
      err.errors[:klass].should include("can't be blank")
    end

    it 'requires an environment' do
      err = Fabricate.build(:err, :environment => nil)
      err.should_not be_valid
      err.errors[:environment].should include("can't be blank")
    end
  end

end

