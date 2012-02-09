require 'spec_helper'

describe HappyMapper::Attribute do
  describe "initialization" do
    before do
      @attr = HappyMapper::Attribute.new(:foo, String)
    end

    it 'should know that it is an attribute' do
      @attr.attribute?.should be_true
    end

    it 'should know that it is NOT an element' do
      @attr.element?.should be_false
    end
  end
end