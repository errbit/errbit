# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::DestroyProblemsByAppJob do
  it "destroys problems for an app" do
    app = create(:errbit_app)
    problem = create(:errbit_problem, app: app)

    described_class.perform_now(app.id)

    expect(Errbit::Problem.where(id: problem.id)).to be_empty
  end

  it "ignores missing apps" do
    expect { described_class.perform_now(999_999) }.not_to raise_error
  end
end
