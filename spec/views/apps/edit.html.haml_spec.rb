# frozen_string_literal: true

require "rails_helper"

RSpec.describe "apps/edit.html.haml", type: :view do
  let(:app) { stub_model(App) }
  let(:app_decorate) { AppDecorator.new(app) }

  before do
    allow(view).to receive(:app).and_return(app)
    allow(view).to receive(:app_decorate).and_return(app_decorate)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
  end

  describe "content_for :action_bar" do
    def action_bar
      view.content_for(:action_bar)
    end

    it "should confirm the 'reset' link" do
      render
      expect(action_bar).to have_selector(
        format(
          'a.button[data-confirm="%s"]',
          I18n.t("apps.confirm_destroy_all_problems")
        )
      )
    end

    it "should confirm the 'destroy' link" do
      render
      expect(action_bar).to have_selector(
        format(
          'a.button[data-confirm="%s"]',
          I18n.t("apps.confirm_delete")
        )
      )
    end
  end

  context "with invalid app" do
    let(:app) do
      app = stub_model(App)
      app.errors.add(:base, "You must specify your")
      app
    end

    it "see the error" do
      render
      expect(rendered).to match(/You must specify your/)
    end
  end
end
