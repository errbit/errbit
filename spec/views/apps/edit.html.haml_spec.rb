require 'spec_helper'

describe "apps/edit.html.haml" do
  before do
    app = stub_model(App)
    view.stub(:app).and_return(app)
    controller.stub(:current_user) { stub_model(User) }
  end

  describe "content_for :action_bar" do
    def action_bar
      view.content_for(:action_bar)
    end

    it "should confirm the 'destroy' link" do
      render

      action_bar.should have_selector('a.button[data-confirm="Seriously?"]')
    end

  end
end

