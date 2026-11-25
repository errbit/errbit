# frozen_string_literal: true

require "rails_helper"

RSpec.describe "apps/show.atom.builder", type: :view do
  let(:notice) { create(:notice) }

  let(:app) { notice.app }

  let(:problems) { [notice.problem] }

  before do
    assign(:app, app)
    assign(:problems, problems)
  end

  context "with errs" do
    it "see the errs message" do
      render

      expect(rendered).to match(problems.first.message)
    end
  end
end
