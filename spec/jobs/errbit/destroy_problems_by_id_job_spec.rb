# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::DestroyProblemsByIdJob do
  it "destroys problems by id" do
    problem = create(:errbit_problem)

    described_class.perform_now([problem.id])

    expect(Errbit::Problem.where(id: problem.id)).to be_empty
  end
end
