# frozen_string_literal: true

require "rails_helper"

RSpec.describe "issue_trackers/text.erb", type: :view do
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
end
