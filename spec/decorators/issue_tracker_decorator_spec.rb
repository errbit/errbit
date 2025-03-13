describe IssueTrackerDecorator do
  let(:fake_tracker) do
    klass = Class.new(ErrbitPlugin::IssueTracker) do
      def self.label
        "fake"
      end

      def self.note
        "a note"
      end

      def self.fields
        {
          foo: {label: "foo"},
          bar: {label: "bar"}
        }
      end

      def configured?
        true
      end
    end
    klass.new "nothing special"
  end

  let(:issue_tracker) do
    it = IssueTracker.new
    allow(it).to receive(:tracker).and_return(fake_tracker)
    it
  end

  let(:decorator) do
    IssueTrackerDecorator.new(issue_tracker)
  end

  describe "#type" do
    it "returns decorator for the issue tracker class" do
      expect(decorator.type.class).to eq(IssueTrackerTypeDecorator)
    end
  end
end
