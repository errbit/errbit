# frozen_string_literal: true

require "rails_helper"

RSpec.describe DestroyProblemsByIdJob, type: :job do
  before do
    @app = Fabricate(:app)
    @problem1 = Fabricate(:problem, app: @app)
    @problem2 = Fabricate(:problem, app: @app)
    @problem3 = Fabricate(:problem, app: @app)
    @problem4 = Fabricate(:problem, app: @app)
    @problem5 = Fabricate(:problem, app: @app)
    @problem6 = Fabricate(:problem, app: @app)
  end

  it "destroys all selected problems" do
    expect do
      DestroyProblemsByIdJob.perform_later([@problem2.id.to_s, @problem5.id.to_s, @problem1.id.to_s])
    end.to change(Problem, :count).by(-3)
    expect(@app.problems.count).to eq 3
  end

  it "destroys all selected problems, even with a large amount of them" do
    app2 = Fabricate(:app)
    500.times do
      Fabricate(:problem, app: app2)
    end
    expect do
      DestroyProblemsByIdJob.perform_later(app2.problems.to_a.sample(100).map(&:id).map(&:to_s))
    end.to change(Problem, :count).by(-100)
    expect(app2.problems.count).to eq 400
  end

  it "should work with a fresh new application" do
    app2 = Fabricate(:app)
    expect do
      DestroyProblemsByIdJob.perform_later([])
    end.to change(Problem, :count).by(0)
    expect(app2.problems.count).to eq 0
  end
end
