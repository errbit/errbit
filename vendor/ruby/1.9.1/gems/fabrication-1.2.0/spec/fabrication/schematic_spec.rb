require 'spec_helper'

describe Fabrication::Schematic do

  let(:schematic) do
    Fabrication::Schematic.new(OpenStruct) do
      name "Orgasmo"
      something(:param => 2) { "hi!" }
      another_thing { 25 }
    end
  end

  describe "generator selection" do
    context "for an activerecord object" do
      it "uses the activerecord generator" do
        Fabrication::Schematic.new(Division).generator.should == Fabrication::Generator::ActiveRecord
      end
    end
    context "for a mongoid object" do
      it "uses the base generator" do
        Fabrication::Schematic.new(Author).generator.should == Fabrication::Generator::Mongoid
      end
    end
    context "for a sequel object" do
      it "uses the base generator" do
        Fabrication::Schematic.new(ParentSequelModel).generator.should == Fabrication::Generator::Sequel
      end
    end
  end

  describe ".new" do
    it "stores the klass" do
      schematic.klass.should == OpenStruct
    end
    it "stores the generator" do
      schematic.generator.should == Fabrication::Generator::Base
    end
    it "stores the attributes" do
      schematic.attributes.size.should == 3
    end
  end

  describe "#attribute" do
    it "returns the requested attribute if it exists" do
      schematic.attribute(:name).name.should == :name
    end
    it "returns nil if it does not exist" do
      schematic.attribute(:not_there).should be_nil
    end
  end

  describe "#attributes" do
    it "always returns an empty array" do
      schematic.attributes = nil
      schematic.attributes.should == []
    end
  end

  describe "#generate" do

    context "an instance" do

      it "generates a new instance" do
        schematic.generate.should be_kind_of(OpenStruct)
      end

    end

    context "an attributes hash" do

      let(:hash) { schematic.generate(:attributes => true) }

      it "generates a hash with the object's attributes" do
        hash.should be_kind_of(Hash)
      end

      it "has the correct attributes" do
        hash.size.should == 3
        hash[:name].should == 'Orgasmo'
        hash[:something].should == "hi!"
        hash[:another_thing].should == 25
      end

    end

  end

  describe "#merge" do

    context "without inheritance" do

      subject { schematic }

      it "stored 'name' correctly" do
        attribute = subject.attribute(:name)
        attribute.name.should == :name
        attribute.params.should == {}
        attribute.value.should == "Orgasmo"
      end

      it "stored 'something' correctly" do
        attribute = subject.attribute(:something)
        attribute.name.should == :something
        attribute.params.should == { :param => 2 }
        Proc.should === attribute.value
        attribute.value.call.should == "hi!"
      end

      it "stored 'another_thing' correctly" do
        attribute = subject.attribute(:another_thing)
        attribute.name.should == :another_thing
        attribute.params.should == {}
        Proc.should === attribute.value
        attribute.value.call.should == 25
      end

    end

    context "with inheritance" do

      subject do
        schematic.merge do
          name { "Willis" }
          something "Else!"
          another_thing(:thats_what => 'she_said') { "Boo-ya!" }
        end
      end

      it "stored 'name' correctly" do
        attribute = subject.attribute(:name)
        attribute.name.should == :name
        attribute.params.should == {}
        Proc.should === attribute.value
        attribute.value.call.should == "Willis"
      end

      it "stored 'something' correctly" do
        attribute = subject.attribute(:something)
        attribute.name.should == :something
        attribute.params.should == {}
        attribute.value.should == "Else!"
      end

      it "stored 'another_thing' correctly" do
        attribute = subject.attribute(:another_thing)
        attribute.name.should == :another_thing
        attribute.params.should == { :thats_what => 'she_said' }
        Proc.should === attribute.value
        attribute.value.call.should == "Boo-ya!"
      end

    end

  end

  describe "#on_init" do
    let(:init_block) { lambda {} }
    let(:init_schematic) do
      block = init_block
      Fabrication::Schematic.new(OpenStruct) do
        on_init &block
      end
    end

    it "stores the on_init callback" do
      init_schematic.callbacks[:on_init].should == init_block
    end

    context "with inheritance" do
      let(:child_block) { lambda {} }
      let(:child_schematic) do
        block = child_block
        init_schematic.merge do
          on_init &block
        end
      end

      it "overwrites the on_init callback" do
        child_schematic.callbacks[:on_init].should == child_block
      end
    end
  end

  context "when overriding" do
    let(:address) { Address.new }

    it "symbolizes attribute keys" do
      Fabricator(:address) do
        city { raise 'should not be called' }
      end
      Fabricator(:contact) do
        address
      end
      lambda do
        Fabricate(:contact, 'address' => address)
      end.should_not raise_error(RuntimeError)
    end
  end
end
