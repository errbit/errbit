# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteConfigController, type: :controller do
  it_requires_admin_privileges for: {
    index: :get,
    update: :patch
  }

  let(:admin) { create(:errbit_user, admin: true) }

  before { sign_in admin }

  describe "#index" do
    it "responds successfully" do
      get :index

      expect(response).to be_successful
    end
  end

  describe "#update" do
    it "writes the submitted fingerprinter fields to SiteConfig" do
      patch :update, params: {
        site_config: {
          notice_fingerprinter_attributes: {
            backtrace_lines: 3,
            environment_name: false
          }
        }
      }

      document = Errbit::SiteConfig.document

      expect(document.environment_name).to eq(false)
      expect(document.backtrace_lines).to eq(3)
    end

    it "redirects to the index" do
      patch :update, params: {
        site_config: {notice_fingerprinter_attributes: {error_class: true}}
      }

      expect(response).to redirect_to(site_config_index_path)
    end

    it "flashes a confirmation" do
      patch :update, params: {
        site_config: {notice_fingerprinter_attributes: {error_class: true}}
      }

      expect(request.flash[:success]).to eq("Updated site config")
    end

    context "with an Errbit::App that follows the site-wide fingerprinter" do
      let!(:app) do
        a = create(:errbit_app)
        # The before_create callback auto-builds a "site"-sourced fingerprinter;
        # update its values to the test's baseline.
        a.notice_fingerprinter.update!(
          error_class: true,
          message: true,
          backtrace_lines: -1,
          component: true,
          action: true,
          environment_name: true,
          source: Errbit::SiteConfig::CONFIG_SOURCE_SITE
        )
        a
      end

      it "propagates the change to the app's fingerprinter" do
        patch :update, params: {
          site_config: {
            notice_fingerprinter_attributes: {backtrace_lines: 11, environment_name: false}
          }
        }

        app.reload
        expect(app.notice_fingerprinter.backtrace_lines).to eq(11)
        expect(app.notice_fingerprinter.environment_name).to eq(false)
      end
    end

    context "with an Errbit::App that has opted into a per-app fingerprinter" do
      let!(:app) do
        a = create(:errbit_app)
        a.notice_fingerprinter.update!(
          error_class: true,
          message: true,
          backtrace_lines: 5,
          component: true,
          action: true,
          environment_name: true,
          source: Errbit::SiteConfig::CONFIG_SOURCE_APP
        )
        a
      end

      it "leaves the app's fingerprinter untouched" do
        patch :update, params: {
          site_config: {
            notice_fingerprinter_attributes: {backtrace_lines: 99, environment_name: false}
          }
        }

        app.reload
        expect(app.notice_fingerprinter.backtrace_lines).to eq(5)
        expect(app.notice_fingerprinter.environment_name).to eq(true)
      end
    end
  end
end
