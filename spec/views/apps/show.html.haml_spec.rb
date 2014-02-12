require 'spec_helper'

describe "apps/show.html.haml" do
  let(:app) { stub_model(App) }
  let(:user) { stub_model(User) }

  let(:action_bar) do
    view.content_for(:action_bar)
  end

  before do
    view.stub(:app).and_return(app)
    view.stub(:all_errs).and_return(false)
    view.stub(:deploys).and_return([])
    controller.stub(:current_user) { user }
  end

  describe "content_for :action_bar" do

    it "should confirm the 'cancel' link" do
      render

      expect(action_bar).to have_selector('a.button', :text => 'all errs')
    end

  end

  context "without errs" do
    it 'see no errs' do
      render
      expect(rendered).to match(/No errs have been/)
    end
  end

  context "with user watch application" do
    before do
      user.stub(:watching?).with(app).and_return(true)
    end
    it 'see the unwatch button' do
      render
      expect(action_bar).to include(I18n.t('apps.show.unwatch'))
    end
  end

  context "with user not watch application" do
    before do
      user.stub(:watching?).with(app).and_return(false)
    end
    it 'not see the unwatch button' do
      render
      expect(action_bar).to_not include(I18n.t('apps.show.unwatch'))
    end
  end

end

