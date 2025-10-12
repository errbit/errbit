# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppPolicy do
  subject { described_class.new(user, record) }

  describe "#initialize" do
    context "when user not present" do
      let(:record) { create(:app) }

      let(:user) { nil }

      it { expect { subject }.to raise_error(Pundit::NotAuthorizedError) }
    end
  end
end
