require 'spec_helper'

describe FilterCriteria do
  context "attributes" do
    it { should have_fields(:message, :error_class, :url, :where) }
  end

  let!(:filter) { Fabricate.build(:filter_criteria) }
  let(:notice) { Fabricate.build(:notice, error_class: 'FooError') }
  before do
    allow(notice).to receive(:url).and_return('http://example.com/apple-touch-icon.png')
    allow(notice).to receive(:where).and_return('application#index')
  end

  context 'validation' do
    it 'is valid with one criterium' do
      filter.where = 'test'
      expect(filter.valid?).to eq true
    end

    it 'is invalid with no criterium' do
      expect(filter.valid?).to eq false
    end
  end

  context 'message' do
    it 'matches "Too Much Bar"' do
      filter.message = 'Too Much Bar'
      expect(filter.pass? notice).to eq false
    end

    it 'matches not "abc123"' do
      filter.message = 'abc123'
      expect(filter.pass? notice).to eq true
    end

    it 'matches "^FooError" as regex' do
      filter.message = '^FooError'
      expect(filter.pass? notice).to eq false
    end

    it 'matches "FooError:(.*?)Bar" as regex' do
      filter.message = 'FooError:(.*?)Bar'
      expect(filter.pass? notice).to eq false
    end
  end

  context 'error_class' do
    it 'matches "FooError"' do
      filter.error_class = 'FooError'
      expect(filter.pass? notice).to eq false
    end

    it 'matches "Error" in part' do
      filter.error_class = 'Error'
      expect(filter.pass? notice).to eq false
    end

    it 'matches not "abc123"' do
      filter.error_class = 'abc123'
      expect(filter.pass? notice).to eq true
    end

    it 'matches "Foo(Bar|Error)" as regex' do
      filter.error_class = 'Foo(Bar|Error)'
      expect(filter.pass? notice).to eq false
    end
  end

  context 'url' do
    it 'matches "http://example.com"' do
      filter.url = 'http://example.com'
      expect(filter.pass? notice).to eq false
    end

    it 'matches "example" in part' do
      filter.url = 'example'
      expect(filter.pass? notice).to eq false
    end

    it 'matches not "abc123"' do
      filter.url = 'abc123'
      expect(filter.pass? notice).to eq true
    end

    it 'matches "http://example\.com/(.*?)\.png" as regex' do
      filter.url = 'http://example\.com/(.*?)\.png'
      expect(filter.pass? notice).to eq false
    end
  end

  context 'where' do
    it 'matches "application#index"' do
      filter.where = 'application#index'
      expect(filter.pass? notice).to eq false
    end

    it 'matches "#index" in part' do
      filter.where = '#index'
      expect(filter.pass? notice).to eq false
    end

    it 'matches not "abc123"' do
      filter.where = 'abc123'
      expect(filter.pass? notice).to eq true
    end

    it 'matches "application#(test|index)" as regex' do
      filter.where = 'application#(test|index)'
      expect(filter.pass? notice).to eq false
    end
  end

  context 'multiple criteria' do
    it 'passes when all are not found' do
      filter.where = 'application#help'
      filter.error_class = 'FooBar'
      expect(filter.pass? notice).to eq true
    end

    it 'passes even when one matches' do
      filter.where = 'application#index'
      filter.error_class = 'FooBar'
      expect(filter.pass? notice).to eq true
    end

    it 'fails when all criteria matches' do
      filter.where = 'application#index'
      filter.error_class = 'FooError'
      expect(filter.pass? notice).to eq false
    end
  end

end
