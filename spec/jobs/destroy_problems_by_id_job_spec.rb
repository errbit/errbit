# frozen_string_literal: true

require "rails_helper"

RSpec.describe DestroyProblemsByIdJob, type: :job do
  it { expect(subject).to be_an(ApplicationJob) }

  it "destroys all selected problems" do
    app = Fabricate(:app)
    problem1 = Fabricate(:problem, app: app)

    expect do
      DestroyProblemsByIdJob.perform_later([problem1.id])
    end.to change(Problem, :count).by(-1)

    expect(app.problems.count).to eq(0)
  end

  it "should work with a fresh new application" do
    app = Fabricate(:app)

    expect do
      DestroyProblemsByIdJob.perform_later([])
    end.not_to change(Problem, :count)

    expect(app.problems.count).to eq(0)
  end
end
