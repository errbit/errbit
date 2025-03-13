describe "problems/show.html.ics", type: "view" do
  let(:problem) { ProblemDecorator.new(Fabricate(:problem)) }

  before do
    allow(view).to receive(:problem).and_return(problem)
  end

  it "works" do
    render template: "problems/show", formats: [:ics], handlers: [:haml]
  end
end
