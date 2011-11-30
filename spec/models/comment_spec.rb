require 'spec_helper'

describe Comment do
  context 'validations' do
    it 'should require a body' do
      comment = Fabricate.build(:comment, :body => nil)
      comment.should_not be_valid
      comment.errors[:body].should include("can't be blank")
    end
  end
end

