# frozen_string_literal: true

require "rails_helper"

RSpec.describe "problems/index.html.erb", type: :view do
  let(:problem_1) { create(:problem) }

  let(:problem_2) { create(:problem, app: problem_1.app) }

  before do
    assign(:selected_problems, [])
    assign(:all_errs, false)
    assign(:problems, Kaminari.paginate_array([problem_1, problem_2]).page(1).per(10))
    assign(:params_sort, "last_notice_at")
    assign(:params_order, "asc")

    allow(controller).to receive(:current_user).and_return(create(:user))
  end

  describe "with problem" do
    before { problem_1 && problem_2 }

    it "should works" do
      render

      expect(rendered).to have_selector("div#problem_table.problem_table")
    end
  end

  describe "show/hide resolved button behavior" do
    it "displays unresolved errors title and button" do
      assign(:all_errs, false)

      render

      expect(view.content_for(:title)).to match "Unresolved Errors"
      expect(view.content_for(:action_bar)).to have_link "show resolved"
    end

    it "displays all errors title and button" do
      assign(:all_errs, true)

      render

      expect(view.content_for(:title)).to match "All Errors"
      expect(view.content_for(:action_bar)).to have_link "hide resolved"
    end
  end
end
