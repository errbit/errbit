require 'spec_helper'

describe IssueTrackerDecorator do

    class Foo
      Note = 'hello <strong></strong>'
      Fields = [
        [:foo, :bar]
      ]
      Label = 'foo'
      def self.label; Label; end
      def _type
        'Foo'
      end
    end

    class Bar
      Label = 'bar'
      def self.label; Label; end
      def _type
        'Bar'
      end
    end

  describe "#note" do


    it 'return the html_safe of Note' do
      expect(IssueTrackerDecorator.new(Foo).note).to eql 'hello <strong></strong>'.html_safe
    end
  end

  describe "#issue_trackers" do
    it 'return an array of IssueTrackerDecorator' do
      IssueTrackerDecorator.new(Foo).issue_trackers do |it|
        expect(it).to be_a(IssueTrackerDecorator)
      end
    end
  end

  describe "#fields" do
    it 'return all Fields define decorate' do
      IssueTrackerDecorator.new(Foo).fields do |itf|
        expect(itf).to be_a(IssueTrackerFieldDecorator)
        expect(itf.object).to eql :foo
        expect(itf.field_info).to eql :bar
      end
    end
  end

  describe "#params_class" do
    it 'add the label in class' do
      expect(IssueTrackerDecorator.new(Bar).params_class(Foo.new)).to eql 'bar'
    end
    it 'add chosen class if _type is same' do
      expect(IssueTrackerDecorator.new(Foo).params_class(Foo.new)).to eql 'chosen foo'
    end
  end
end
