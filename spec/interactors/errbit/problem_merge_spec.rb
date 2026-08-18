# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::ProblemMerge do
  let(:app) { create(:errbit_app) }
  let(:merged_problem) { create(:errbit_problem, app: app) }
  let(:child_problem) { create(:errbit_problem, app: app) }

  it "requires at least two unique problems" do
    expect { described_class.new(merged_problem) }.to raise_error(ArgumentError)
  end

  it "moves errs and comments to the first problem and removes child problems" do
    merged_err = create(:errbit_err, problem: merged_problem)
    child_err = create(:errbit_err, problem: child_problem)
    user = create(:errbit_user)
    create(:errbit_comment, err: merged_problem, user: user)
    child_comment = create(:errbit_comment, err: child_problem, user: user)

    expect { described_class.new(merged_problem, child_problem).merge }
      .to change(Errbit::Problem, :count).by(-1)

    expect(merged_problem.reload.errs.pluck(:id).sort).to eq([merged_err.id, child_err.id].sort)
    expect(child_comment.reload.err).to eq(merged_problem)
    expect(merged_problem.comments_count).to eq(2)
  end
end
