require 'spec_helper'

describe Err do

  context 'validations' do
    it 'requires a error_class' do
      err = Fabricate.build(:err, :error_class => nil)
      err.should_not be_valid
      err.errors[:error_class].should include("can't be blank")
    end

    it 'requires an environment' do
      err = Fabricate.build(:err, :environment => nil)
      err.should_not be_valid
      err.errors[:environment].should include("can't be blank")
    end
  end

end

