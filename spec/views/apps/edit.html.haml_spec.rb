require 'spec_helper'

describe "apps/edit.html.haml" do
  let(:app) { stub_model(App) }
  before do
    view.stub(:app).and_return(app)
    controller.stub(:current_user) { stub_model(User) }
  end

  describe "content_for :action_bar" do
    def action_bar
      view.content_for(:action_bar)
    end

    it "should confirm the 'reset' link" do
      render
      expect(action_bar).to have_selector('a.button[data-confirm="%s"]' % I18n.t('apps.confirm_destroy_all_problems'))
    end

    it "should confirm the 'destroy' link" do
      render
      expect(action_bar).to have_selector('a.button[data-confirm="%s"]' % I18n.t('apps.confirm_delete'))
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

