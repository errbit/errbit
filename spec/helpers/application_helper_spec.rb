# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  let(:notice) { Fabricate(:notice) }
  describe "#generate_problem_ical" do
    it "return the ical format" do
      helper.generate_problem_ical([notice])
    end
  end
end
