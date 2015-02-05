describe "issue_trackers/issue.txt.erb", type: 'view' do
  let(:problem) {
    problem = Fabricate(:problem)
    Fabricate(:notice, :err => Fabricate(:err, :problem => problem))
    problem
  }

  before do
    allow(view).to receive(:problem).and_return(problem)
  end

  it "has the problem url" do
    render
    expect(rendered).to match(app_problem_url problem.app, problem)
  end
end
