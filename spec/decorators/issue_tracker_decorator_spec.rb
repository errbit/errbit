require 'spec_helper'

describe IssueTrackerDecorator do
  let(:fake_tracker) do
    Class.new(ErrbitPlugin::IssueTracker) do
      def self.label; 'fake'; end
      def self.note; 'a note'; end
      def self.fields
        {
          :foo => {:label => 'foo'},
          :bar => {:label => 'bar'}
        }
      end

      def configured?; true; end
    end
  end

  let(:decorator) do
    IssueTrackerDecorator.new(fake_tracker, 'fake')
  end

  describe "#note" do
    it 'return the html_safe of Note' do
      expect(decorator.note).to eql fake_tracker.note
    end
  end

  describe "#issue_trackers" do
    it 'return an array of IssueTrackerDecorator' do
      decorator.issue_trackers do |it|
        expect(it).to be_a(IssueTrackerDecorator)
      end
    end
  end

  describe "#fields" do
    it 'return all Fields define decorate' do
      decorator.fields do |itf|
        expect(itf).to be_a(IssueTrackerFieldDecorator)
        expect([:foo, :bar]).to be_include(itf.object)
        expect([{:label => 'foo'}, {:label => 'bar'}]).to be_include(itf.field_info)
      end
    end
  end

  describe "#params_class" do
    it 'add the label in class' do
      expect(decorator.params_class(IssueTracker.new(:type_tracker => 'none'))).to eql 'fake'
    end
    it 'add chosen class if _type is same' do
      expect(decorator.params_class(IssueTracker.new(:type_tracker => 'fake'))).to eql 'chosen fake'
    end
  end
end
