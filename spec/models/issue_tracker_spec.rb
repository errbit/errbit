require 'spec_helper'

describe IssueTracker do
  describe "Association" do
    it { should be_embedded_in(:app) }
  end

  describe "Attributes" do
    it { should have_field(:type_tracker).of_type(String) }
    it { should have_field(:options).of_type(Hash).with_default_value_of({}) }
  end

  describe "#tracker" do
    context "with type_tracker class not exist" do
      it 'return NullIssueTracker' do
        expect(IssueTracker.new(:type_tracker => 'Foo').tracker).to be_a ErrbitPlugin::NoneIssueTracker
      end
    end
  end
end
