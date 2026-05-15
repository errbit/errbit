# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::ProblemDecorator, type: :decorator do
  it "decorates an Errbit::Problem" do
    problem = create(:errbit_problem)

    expect(described_class.new(problem).object).to eq(problem)
  end

  it "decorates the notices association" do
    problem = create(:errbit_problem)
    err = create(:errbit_err, problem: problem)
    create(:errbit_notice, err: err, app: problem.app)

    decorated = described_class.new(problem)

    expect(decorated.notices.first).to be_a(Errbit::NoticeDecorator)
  end
end
