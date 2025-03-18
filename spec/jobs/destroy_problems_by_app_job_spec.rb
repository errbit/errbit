# frozen_string_literal: true

require "rails_helper"

RSpec.describe DestroyProblemsByAppJob, type: :job do
  before do
    @app = Fabricate(:app)
    @problem1 = Fabricate(:problem, app: @app)
    @problem2 = Fabricate(:problem, app: @app)
  end

  it "destroys all problems" do
    expect do
      DestroyProblemsByAppJob.perform_later(@app.id)
    end.to change(Problem, :count).by(-2)
    expect(@app.problems.count).to eq 0
  end

  it "destroys all problems, even with a large amount of them" do
    app2 = Fabricate(:app)
    500.times do
      Fabricate(:problem, app: app2)
    end
    expect do
      DestroyProblemsByAppJob.perform_later(app2.id)
    end.to change(Problem, :count).by(-500)
    expect(app2.problems.count).to eq 0
  end

  it "should work with a fresh new application" do
    app2 = Fabricate(:app)
    expect do
      DestroyProblemsByAppJob.perform_later(app2.id)
    end.to change(Problem, :count).by(0)
    expect(app2.problems.count).to eq 0
  end
end
