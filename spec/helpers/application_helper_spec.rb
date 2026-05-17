# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  let(:notice) { create(:errbit_notice) }

  describe "#generate_problem_ical" do
    it "renders the ical format without raising" do
      expect { helper.generate_problem_ical([notice]) }.not_to raise_error
    end
  end
end
