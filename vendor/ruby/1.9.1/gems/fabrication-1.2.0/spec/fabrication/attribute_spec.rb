require 'spec_helper'

describe Fabrication::Attribute do

  describe ".new" do

    context "with name, params, and a static value" do

      subject do
        Fabrication::Attribute.new("a", {:b => 1}, "c")
      end

      its(:name)   { should == "a" }
      its(:params) { should == {:b => 1} }
      its(:value)  { should == "c" }

    end

    context "with a block value" do

      subject do
        Fabrication::Attribute.new("a", nil, Proc.new { "c" })
      end

      it "has a proc for a value" do
        Proc.should === subject.value
      end

    end

    context "with a nil value" do

      subject do
        Fabrication::Attribute.new("a", nil, nil)
      end

      its(:value) { should be_nil }

    end

    context "with nil params" do

      subject do
        Fabrication::Attribute.new("a", nil, nil)
      end

      its(:params) { should be_nil }

    end

  end

end
