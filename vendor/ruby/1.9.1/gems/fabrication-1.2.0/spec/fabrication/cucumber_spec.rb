require 'spec_helper'
require 'fabrication/cucumber'

describe Fabrication::Cucumber do
  include described_class

  let(:name) { 'dogs' }

  describe '#klass' do
    context 'with a schematic for class "Boom"' do
      subject { StepFabricator.new(name).klass }
      let(:fabricator_name) { :dog }

      before do
        Fabrication::Fabricator.schematics.stub(:[])
          .with(fabricator_name).and_return(stub(:klass => "Boom"))
      end

      it { should == "Boom" }

      context "given a human name" do
        let(:name) { "weiner dogs" }
        let(:fabricator_name) { :weiner_dog }
        it { should == "Boom" }
      end

      context "given a titlecase human name" do
        let(:name) { "Weiner Dog" }
        let(:fabricator_name) { :weiner_dog }
        it { should == "Boom" }
      end
    end
  end

  describe "#n" do
    let(:n) { 3 }
    let(:fabricator) { StepFabricator.new(name) }

    it "fabricates n times" do
      Fabrication::Fabricator.should_receive(:generate).with(:dog, anything, {}).exactly(n).times
      fabricator.n n
    end

    it "fabricates with attrs" do
      Fabrication::Fabricator.should_receive(:generate)
        .with(anything, anything, :collar => 'red').at_least(1)
      fabricator.n n, :collar => 'red'
    end

    context 'with a plural subject' do
      let(:name) { 'dogs' }
      it 'remembers' do
        Fabrication::Fabricator.stub(:generate).and_return("dog1", "dog2", "dog3")
        fabricator.n n
        Fabrications[name].should == ["dog1", "dog2", "dog3"]
      end
    end

    context 'with a singular subject' do
      let(:name) { 'dog' }
      it 'remembers' do
        Fabrication::Fabricator.stub(:generate).and_return("dog1")
        fabricator.n 1
        Fabrications[name].should == 'dog1'
      end
    end

  end

  describe '#from_table' do
    it 'maps column names to attribute names' do
      table = stub(:hashes => [{ 'Favorite Color' => 'pink' }])
      Fabrication::Fabricator.should_receive(:generate)
        .with(anything, anything, :favorite_color => 'pink')
      StepFabricator.new('bears').from_table(table)
    end

    context 'with a plural subject' do
      let(:table) { double("ASTable", :hashes => hashes) }
      let(:hashes) do
        [{'some' => 'thing'},
         {'some' => 'panother'}]
      end
      it 'fabricates with each rows attributes' do
        Fabrication::Fabricator.should_receive(:generate)
          .with(:dog, anything, {:some => 'thing'})
        Fabrication::Fabricator.should_receive(:generate)
          .with(:dog, anything, {:some => 'panother'})
        StepFabricator.new(name).from_table(table)
      end
      it 'remembers' do
        Fabrication::Fabricator.stub(:generate).and_return('dog1', 'dog2')
        StepFabricator.new(name).from_table(table)
        Fabrications[name].should == ["dog1", "dog2"]
      end
    end

    context 'singular' do
      let(:name) { 'dog' }
      let(:table) { double("ASTable", :rows_hash => rows_hash) }
      let(:rows_hash) do
        {'some' => 'thing'}
      end
      it 'fabricates with each row as an attribute' do
        Fabrication::Fabricator.should_receive(:generate).with(:dog, anything, {:some => 'thing'})
        StepFabricator.new(name).from_table(table)
      end
      it 'remembers' do
        Fabrication::Fabricator.stub(:generate).and_return('dog1')
        StepFabricator.new(name).from_table(table)
        Fabrications[name].should == "dog1"
      end
    end
  end

end
