# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::DestroyProblemsByAppJob, type: :job do
  it { expect(subject).to be_an(Errbit::ApplicationJob) }

  it "destroys all problems for the given app" do
    app = create(:errbit_app)
    create(:errbit_problem, app: app)

    expect {
      described_class.perform_later(app.id)
    }.to change(Errbit::Problem, :count).by(-1)

    expect(app.problems.reload.count).to eq(0)
  end

  it "is a no-op when the app has no problems" do
    app = create(:errbit_app)

    expect {
      described_class.perform_later(app.id)
    }.not_to change(Errbit::Problem, :count)

    expect(app.problems.reload.count).to eq(0)
  end

  it "is a no-op when the app does not exist" do
    expect {
      described_class.perform_later(999_999_999)
    }.not_to change(Errbit::Problem, :count)
  end
end
