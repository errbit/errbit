require 'spec_helper'

describe Fabrication::Sequencer do

  context 'with no arguments' do
    subject { Fabrication::Sequencer.sequence }

    it { should == 0 }
    it 'creates a default sequencer' do
      Fabrication::Sequencer.sequences[:_default].should == 1
    end
  end

  context 'with only a name' do

    it 'starts with 0' do
      Fabricate.sequence(:incr).should == 0
    end

    it 'increments by one with each call' do
      Fabricate.sequence(:incr).should == 1
      Fabricate.sequence(:incr).should == 2
      Fabricate.sequence(:incr).should == 3
      Fabricate.sequence(:incr).should == 4
    end

    it 'increments counters separately' do
      Fabricate.sequence(:number).should == 0
      Fabricate.sequence(:number).should == 1
      Fabricate.sequence(:number).should == 2
      Fabricate.sequence(:number).should == 3
    end

  end

  context 'with a name and starting number' do

    it 'starts with the number provided' do
      Fabricate.sequence(:higher, 69).should == 69
    end

    it 'increments by one with each call' do
      Fabricate.sequence(:higher).should == 70
      Fabricate.sequence(:higher, 69).should == 71
      Fabricate.sequence(:higher).should == 72
      Fabricate.sequence(:higher).should == 73
    end

  end

  context 'with a block' do

    it 'yields the number to the block and returns the value' do
      Fabricate.sequence(:email) do |i|
        "user#{i}@example.com"
      end.should == "user0@example.com"
    end

    it 'increments by one with each call' do
      Fabricate.sequence(:email) do |i|
        "user#{i}@example.com"
      end.should == "user1@example.com"

      Fabricate.sequence(:email) do |i|
        "user#{i}@example.com"
      end.should == "user2@example.com"
    end

    context 'and then without a block' do
      it 'remembers the original block' do
        Fabricate.sequence :ordinal, &:ordinalize
        Fabricate.sequence(:ordinal).should == "1st"
      end
      context 'and then with a new block' do
        it 'evaluates the new block' do
          Fabricate.sequence(:ordinal) do |i|
            i ** 2
          end.should == 4
        end
        it 'remembers the new block' do
          Fabricate.sequence(:ordinal).should == 9
        end
      end
    end
  end
  context 'with two sequences declared with blocks' do
    it 'remembers both blocks' do
      Fabricate.sequence(:shapes) do |i|
        %w[square circle rectangle][i % 3]
      end
      Fabricate.sequence(:colors) do |i|
        %w[red green blue][i % 3]
      end
      Fabricate.sequence(:shapes).should == 'circle'
      Fabricate.sequence(:colors).should == 'green'
    end
  end
end
