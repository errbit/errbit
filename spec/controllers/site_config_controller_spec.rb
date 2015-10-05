describe SiteConfigController, type: 'controller' do
  it_requires_admin_privileges for: {
    index: :get,
    update: :put
  }

  let(:admin) { Fabricate(:admin) }

  before { sign_in admin }

  describe '#index' do
    it 'has an index action' do
      get :index
    end
  end

  describe '#update' do
    it 'updates' do
      put :update, site_config: {
        notice_fingerprinter_attributes: {
          backtrace_lines: 3,
          environment_name: false
        }
      }

      fingerprinter = SiteConfig.document.notice_fingerprinter

      expect(fingerprinter.environment_name).to be false
      expect(fingerprinter.backtrace_lines).to be 3
    end

    it 'redirects to the index' do
      put :update, site_config: {
        notice_fingerprinter_attributes: { error_class: true }
      }

      expect(response).to redirect_to(site_config_index_path)
    end

    it 'flashes a confirmation' do
      put :update, site_config: {
        notice_fingerprinter_attributes: { error_class: true }
      }

      expect(request.flash[:success]).to eq 'Updated site config'
    end
  end
end
