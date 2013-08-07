require 'spec_helper'

describe "apps/show.html.haml" do
  let(:app) { stub_model(App) }
  before do
    view.stub(:app).and_return(app)
    view.stub(:all_errs).and_return(false)
    view.stub(:deploys).and_return([])
    controller.stub(:current_user) { stub_model(User) }
  end

  describe "content_for :action_bar" do
    def action_bar
      view.content_for(:action_bar)
    end

    it "should confirm the 'cancel' link" do
      render

      action_bar.should have_selector('a.button', :text => 'all errs')
    end

  end

  context "without errs" do
    it 'see no errs' do
      render
      rendered.should match(/No errs have been/)
    end
  end
end

