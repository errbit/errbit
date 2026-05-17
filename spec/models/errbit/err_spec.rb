# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Err, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_errs table" do
    expect(described_class.table_name).to eq("errbit_errs")
  end

  context "validations" do
    it "requires a fingerprint" do
      err = build(:errbit_err, fingerprint: nil)

      expect(err.valid?).to eq(false)
      expect(err.errors[:fingerprint]).to include("can't be blank")
    end

    it "requires a problem" do
      err = build(:errbit_err, problem: nil)

      expect(err.valid?).to eq(false)
      expect(err.errors[:problem]).to include("must exist")
    end
  end

  describe "associations" do
    it "belongs to a problem" do
      problem = create(:errbit_problem)
      err = create(:errbit_err, problem: problem)

      expect(err.problem).to eq(problem)
    end

    it "is destroyed when its problem is destroyed" do
      err = create(:errbit_err)

      expect {
        err.problem.destroy
      }.to change(described_class, :count).by(-1)
    end
  end

  describe "delegation" do
    it "delegates app to problem" do
      app = create(:errbit_app)
      problem = create(:errbit_problem, app: app)
      err = create(:errbit_err, problem: problem)

      expect(err.app).to eq(app)
    end

    it "delegates resolved? to problem" do
      problem = create(:errbit_problem, resolved: true)
      err = create(:errbit_err, problem: problem)

      expect(err.resolved?).to eq(true)
    end
  end
end
