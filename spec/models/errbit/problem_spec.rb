# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Problem, type: :model do
  it "caches app name when created" do
    app = create(:errbit_app, name: "Cached App")
    problem = create(:errbit_problem, app: app)

    expect(problem.app_name).to eq("Cached App")
  end

  it "updates cached notice attributes" do
    problem = create(:errbit_problem)
    err = create(:errbit_err, problem: problem)
    notice = create(:errbit_notice, err: err, message: "boom")

    described_class.cache_notice(problem.id, notice)
    problem.reload

    expect(problem.notices_count).to eq(1)
    expect(problem.message).to eq("boom")
    expect(problem.hosts.values.first).to include("value" => "example.com", "count" => 1)
  end

  it "supports SQL search over cached text columns" do
    match = create(:errbit_problem, error_class: "SpecialRuntimeError")
    create(:errbit_problem, error_class: "OtherError")

    expect(described_class.search("SpecialRuntime")).to contain_exactly(match)
  end

  it "resolves and unresolves problems" do
    problem = create(:errbit_problem)

    problem.resolve!
    expect(problem).to be_resolved
    expect(problem.resolved_at).to be_present

    problem.unresolve!
    expect(problem).to be_unresolved
    expect(problem.resolved_at).to be_nil
  end
end
