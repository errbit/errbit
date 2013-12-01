require 'spec_helper'

describe Err do

  context 'validations' do
    it 'requires a fingerprint' do
      err = Fabricate.build(:err, :fingerprint => nil)
      expect(err).to_not be_valid
      expect(err.errors[:fingerprint]).to include("can't be blank")
    end

    it 'requires a problem' do
      err = Fabricate.build(:err, :problem_id => nil, :problem => nil)
      expect(err).to_not be_valid
      expect(err.errors[:problem_id]).to include("can't be blank")
    end
  end

end
