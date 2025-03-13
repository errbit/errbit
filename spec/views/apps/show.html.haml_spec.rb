describe "apps/show.html.haml", type: "view" do
  let(:app) { stub_model(App) }
  let(:user) { stub_model(User) }

  let(:action_bar) do
    view.content_for(:action_bar)
  end

  before do
    allow(view).to receive(:app).and_return(app)
    allow(view).to receive(:all_errs).and_return(false)
    allow(view).to receive(:params_order).and_return("asc")
    allow(view).to receive(:params_sort).and_return("latest_notice_at")
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "content_for :action_bar" do
    it "should confirm the 'cancel' link" do
      render

      expect(action_bar).to have_selector("a.button", text: "all errors")
    end
  end

  context "without errs" do
    it "see no errs" do
      render
      expect(rendered).to match(/No errors have been/)
    end
  end

  context "with user watch application" do
    before do
      allow(app).to receive(:watched_by?).with(user).and_return(true)
    end
    it "see the unwatch button" do
      render
      expect(action_bar).to include(I18n.t("apps.show.unwatch"))
    end
  end

  context "with user not watch application" do
    before do
      allow(app).to receive(:watched_by?).with(user).and_return(false)
    end
    it "not see the unwatch button" do
      render
      expect(action_bar).to_not include(I18n.t("apps.show.unwatch"))
    end
  end
end
