describe "apps/index.html.haml", type: 'view' do
  before do
    app = stub_model(App, deploys: [stub_model(Deploy, created_at: Time.zone.now, revision: "123456789abcdef")])
    allow(view).to receive(:apps).and_return([app])
    allow(controller).to receive(:current_user).and_return(stub_model(User))
  end

  describe "deploy column" do
    it "should show the first 7 characters of the revision in parentheses" do
      render
      expect(rendered).to match(/\(1234567\)/)
    end
  end
end
