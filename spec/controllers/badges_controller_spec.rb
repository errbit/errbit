RSpec.describe BadgesController, type: :controller do
  render_views
  let(:app) { Fabricate(:app) }
  let(:user) { Fabricate(:user) }
  let(:problem) do
    Fabricate(:problem, app: app)
  end

  before(:each) do
    sign_in user
  end
  describe "GET /apps/:id/badges" do
    it "shows all badges" do
      get :index, id: app.id
      expect(response).to be_success
    end
  end

  describe "GET /apps/:id/badges/:badge_type" do
    it "shows last_error badge" do
      get :show, id: app.id, badge_type: 'last_error', format: 'svg'
      expect(response).to be_success
    end

    it "shows recent_errors badge" do
      get :show, id: app.id, badge_type: 'recent_errors', format: 'svg'
      expect(response).to be_success
    end
  end
end
