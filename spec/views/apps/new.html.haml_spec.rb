require 'spec_helper'

describe "apps/new.html.haml" do
  let(:app) { stub_model(App) }
  let(:app_decorate) { AppDecorator.new(app) }
  before do
    view.stub(:app).and_return(app)
    view.stub(:app_decorate).and_return(app_decorate)
    controller.stub(:current_user) { stub_model(User) }
  end

  describe "content_for :action_bar" do
    def action_bar
      view.content_for(:action_bar)
    end

    it "should confirm the 'cancel' link" do
      render

      expect(action_bar).to have_selector('a.button', :text => 'cancel')
    end

  end

  context "with unvalid app" do
    let(:app) {
      app = stub_model(App)
      app.errors.add(:base,'You must specify your')
      app
    }

    it 'see the error' do
      render
      expect(rendered).to match(/You must specify your/)
    end
  end

end

