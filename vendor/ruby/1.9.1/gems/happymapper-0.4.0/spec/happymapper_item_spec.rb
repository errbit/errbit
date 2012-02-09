require 'spec_helper'

module Foo
  class Bar; end
end

describe HappyMapper::Item do

  describe "new instance" do
    before do
      @item = HappyMapper::Item.new(:foo, String, :tag => 'foobar')
    end

    it "should accept a name" do
      @item.name.should == 'foo'
    end

    it 'should accept a type' do
      @item.type.should == String
    end

    it 'should accept :tag as an option' do
      @item.tag.should == 'foobar'
    end

    it "should have a method_name" do
      @item.method_name.should == 'foo'
    end
  end

  describe "#constant" do
    it "should just use type if constant" do
      item = HappyMapper::Item.new(:foo, String)
      item.constant.should == String
    end

    it "should convert string type to constant" do
      item = HappyMapper::Item.new(:foo, 'String')
      item.constant.should == String
    end

    it "should convert string with :: to constant" do
      item = HappyMapper::Item.new(:foo, 'Foo::Bar')
      item.constant.should == Foo::Bar
    end
  end

  describe "#method_name" do
    it "should convert dashes to underscores" do
      item = HappyMapper::Item.new(:'foo-bar', String, :tag => 'foobar')
      item.method_name.should == 'foo_bar'
    end
  end

  describe "#xpath" do
    it "should default to tag" do
      item = HappyMapper::Item.new(:foo, String, :tag => 'foobar')
      item.xpath.should == 'foobar'
    end

    it "should prepend with .// if options[:deep] true" do
      item = HappyMapper::Item.new(:foo, String, :tag => 'foobar', :deep => true)
      item.xpath.should == './/foobar'
    end

    it "should prepend namespace if namespace exists" do
      item = HappyMapper::Item.new(:foo, String, :tag => 'foobar')
      item.namespace = 'http://example.com'
      item.xpath.should == 'happymapper:foobar'
    end
  end

  describe "typecasting" do
    it "should work with Strings" do
      item = HappyMapper::Item.new(:foo, String)
      [21, '21'].each do |a|
        item.typecast(a).should == '21'
      end
    end

    it "should work with Integers" do
      item = HappyMapper::Item.new(:foo, Integer)
      [21, 21.0, '21'].each do |a|
        item.typecast(a).should == 21
      end
    end

    it "should work with Floats" do
      item = HappyMapper::Item.new(:foo, Float)
      [21, 21.0, '21'].each do |a|
        item.typecast(a).should == 21.0
      end
    end

    it "should work with Times" do
      item = HappyMapper::Item.new(:foo, Time)
      item.typecast('2000-01-01 01:01:01.123456').should == Time.local(2000, 1, 1, 1, 1, 1, 123456)
    end

    it "should work with Dates" do
      item = HappyMapper::Item.new(:foo, Date)
      item.typecast('2000-01-01').should == Date.new(2000, 1, 1)
    end

    it "should work with DateTimes" do
      item = HappyMapper::Item.new(:foo, DateTime)
      item.typecast('2000-01-01 00:00:00').should == DateTime.new(2000, 1, 1, 0, 0, 0)
    end

    it "should work with Boolean" do
      item = HappyMapper::Item.new(:foo, Boolean)
      item.typecast('false').should == false
    end
  end
end