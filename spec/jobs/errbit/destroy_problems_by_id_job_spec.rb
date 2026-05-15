# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::DestroyProblemsByIdJob, type: :job do
  it { expect(subject).to be_an(Errbit::ApplicationJob) }

  it "destroys the problems with the given ids" do
    app = create(:errbit_app)
    problem = create(:errbit_problem, app: app)

    expect {
      described_class.perform_later([problem.id])
    }.to change(Errbit::Problem, :count).by(-1)

    expect(app.problems.reload.count).to eq(0)
  end

  it "leaves problems whose ids are not in the list" do
    kept = create(:errbit_problem)
    deleted = create(:errbit_problem)

    expect {
      described_class.perform_later([deleted.id])
    }.to change(Errbit::Problem, :count).by(-1)

    expect(Errbit::Problem.find_by(id: kept.id)).to eq(kept)
    expect(Errbit::Problem.find_by(id: deleted.id)).to be_nil
  end

  it "is a no-op when passed an empty list" do
    create(:errbit_problem)

    expect {
      described_class.perform_later([])
    }.not_to change(Errbit::Problem, :count)
  end
end
