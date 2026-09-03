# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::ProblemDestroy do
  let!(:problem) { create(:errbit_problem) }
  let!(:comment) { create(:errbit_comment, err: problem) }
  let!(:err) { create(:errbit_err, problem: problem) }
  let!(:notice) { create(:errbit_notice, err: err) }

  it "deletes the problem and dependent SQL rows" do
    described_class.new(problem).execute

    expect(Errbit::Problem.where(id: problem.id)).to be_empty
    expect(Errbit::Comment.where(id: comment.id)).to be_empty
    expect(Errbit::Err.where(id: err.id)).to be_empty
    expect(Errbit::Notice.where(id: notice.id)).to be_empty
  end

  it "returns the number of destroyed problems" do
    other_problem = create(:errbit_problem)

    expect(described_class.execute([problem, other_problem])).to eq(2)
  end
end
