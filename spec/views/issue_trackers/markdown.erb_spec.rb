# frozen_string_literal: true

require "rails_helper"

RSpec.describe "issue_trackers/markdown.erb", type: :view do
  let(:problem) do
    problem = create(:problem)
    err = create(:err, problem: problem)
    create(:notice, err: err)
    problem
  end

  before do
    allow(view).to receive(:problem).and_return(ProblemDecorator.new(problem))
  end

  it "has the problem url" do
    render

    expect(rendered).to match(app_problem_url(problem.app, problem))
  end

  it "renders the request url as a markdown link" do
    problem.notices.first.update(request: {"url" => "http://example.com/foo"})

    render

    expect(rendered).to include("[http://example.com/foo](http://example.com/foo)")
    expect(rendered).not_to include('")')
    expect(rendered).not_to include(')"')
  end
end
