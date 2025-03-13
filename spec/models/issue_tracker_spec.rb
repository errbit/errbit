describe IssueTracker, type: "model" do
  describe "Association" do
    it { is_expected.to be_embedded_in(:app) }
  end

  describe "Attributes" do
    it { is_expected.to have_field(:type_tracker).of_type(String) }
    it { is_expected.to have_field(:options).of_type(Hash).with_default_value_of({}) }
  end

  describe "#tracker" do
    context "with type_tracker class not exist" do
      let(:app)  { Fabricate(:app) }

      it "return NoneIssueTracker" do
        issue_tracker = IssueTracker.new(type_tracker: "Foo", app: app)
        expect(issue_tracker.tracker).to be_a ErrbitPlugin::NoneIssueTracker
      end
    end
  end
end
