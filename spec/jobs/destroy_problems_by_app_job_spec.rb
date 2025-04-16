# frozen_string_literal: true

require "rails_helper"

RSpec.describe DestroyProblemsByAppJob, type: :job do
  it "destroys all problems" do
    app = Fabricate(:app)
    problem = Fabricate(:problem, app: app)

    expect do
      DestroyProblemsByAppJob.perform_later(app.id)
    end.to change(Problem, :count).by(-1)

    expect(app.problems.count).to eq(0)
  end

  it "should work with a fresh new application" do
    app = Fabricate(:app)

    expect do
      DestroyProblemsByAppJob.perform_later(app.id)
    end.not_to change(Problem, :count)

    expect(app.problems.count).to eq(0)
  end
end
