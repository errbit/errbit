# frozen_string_literal: true

require "rails_helper"

RSpec.describe Err, type: :model do
  context "validations" do
    it "requires a fingerprint" do
      err = build(:err, fingerprint: nil)
      expect(err.valid?).to eq(false)
      expect(err.errors[:fingerprint]).to include("can't be blank")
    end

    it "requires a problem" do
      err = build(:err, problem_id: nil, problem: nil)
      expect(err.valid?).to eq(false)
      expect(err.errors[:problem_id]).to include("can't be blank")
    end
  end
end
