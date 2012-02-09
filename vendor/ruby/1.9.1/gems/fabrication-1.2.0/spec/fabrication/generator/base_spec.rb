require 'spec_helper'

describe Fabrication::Generator::Base do

  describe ".supports?" do
    subject { Fabrication::Generator::Base }
    it "supports any object" do
      subject.supports?(Object).should be_true
    end
  end

  describe "#generate" do

    let(:generator) { Fabrication::Generator::Base.new(Person) }

    let(:attributes) do
      Fabrication::Schematic.new(Person) do
        first_name 'Guy'
        shoes(:count => 4) do |person, index|
          "#{person.first_name}'s shoe #{index}"
        end
      end.attributes
    end

    let(:person) { generator.generate({}, attributes) }

    it 'generates an instance' do
      person.instance_of?(Person).should be_true
    end

    it 'passes the object and count to blocks' do
      person.shoes.should == (1..4).map { |i| "Guy's shoe #{i}" }
    end

    it 'sets the static value' do
      person.instance_variable_get(:@first_name).should == 'Guy'
    end

    context "with on_init block" do
      subject { schematic.generate }

      let(:klass) { Struct.new :arg1, :arg2 }

      context "using init_with" do
        let(:schematic) do
          Fabrication::Schematic.new(klass) do
            on_init { init_with(:a, :b) }
          end
        end

        it "sends the return value of the block to the klass' initialize method" do
          subject.arg1.should == :a
          subject.arg2.should == :b
        end
      end

      context "not using init_with" do
        let(:schematic) do
          Fabrication::Schematic.new(klass) do
            on_init { [ :a, :b ] }
          end
        end

        it "sends the return value of the block to the klass' initialize method" do
          subject.arg1.should == :a
          subject.arg2.should == :b
        end

      end
    end

    context "using an after_create hook" do
      let(:schematic) do
        Fabrication::Schematic.new(Person) do
          first_name "Guy"
          after_create { |k| k.first_name.upcase! }
        end
      end

      it "calls after_create when generated with saving" do
        schematic.generate(:save => true).first_name.should == "GUY"
      end

      it "does not call after_create when generated without saving" do
        schematic.generate(:save => false).first_name.should == "Guy"
      end
    end

  end

  describe "#after_generation" do
    let(:instance) { mock(:instance) }
    let(:generator) { Fabrication::Generator::Base.new(Object) }

    before { generator.send(:instance=, instance) }

    it "saves with a true save flag" do
      instance.should_receive(:save!)
      generator.send(:after_generation, {:save => true})
    end

    it "does not save without a true save flag" do
      instance.should_not_receive(:save)
      generator.send(:after_generation, {})
    end
  end

end
