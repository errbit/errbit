require 'spec_helper'

describe Err do

  context 'validations' do
    it 'requires a fingerprint' do
      err = Fabricate.build(:err, :fingerprint => nil)
      err.should_not be_valid
      err.errors[:fingerprint].should include("can't be blank")
    end

    it 'requires a problem' do
      err = Fabricate.build(:err, :problem_id => nil)
      err.should_not be_valid
      err.errors[:problem_id].should include("can't be blank")
    end
  end

end
