require 'spec_helper'

describe HappyMapper::Element do
  describe "initialization" do
    before do
      @attr = HappyMapper::Element.new(:foo, String)
    end

    it 'should know that it is an element' do
      @attr.element?.should be_true
    end

    it 'should know that it is NOT an attribute' do
      @attr.attribute?.should be_false
    end
  end
end