# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteConfigController, type: :controller do
  it_requires_admin_privileges for: {
    index: :get,
    update: :put
  }

  let(:admin) { Fabricate(:admin) }

  before { sign_in admin }

  describe "#index" do
    it "has an index action" do
      get :index
    end
  end

  describe "#update" do
    it "updates" do
      put :update, params: {
        site_config: {
          notice_fingerprinter_attributes: {
            backtrace_lines: 3,
            environment_name: false
          }
        }
      }

      fingerprinter = SiteConfig.document.notice_fingerprinter

      expect(fingerprinter.environment_name).to eq(false)
      expect(fingerprinter.backtrace_lines).to eq(3)
    end

    it "redirects to the index" do
      put :update, params: {
        site_config: {
          notice_fingerprinter_attributes: {
            error_class: true
          }
        }
      }

      expect(response).to redirect_to(site_config_index_path)
    end

    it "flashes a confirmation" do
      put :update, params: {
        site_config: {
          notice_fingerprinter_attributes: {
            error_class: true
          }
        }
      }

      expect(request.flash[:success]).to eq "Updated site config"
    end

    it "updates apps that are using site wide notice fingerprinter" do
      put :update, params: {
        site_config: {
          notice_fingerprinter_attributes: {
            backtrace_lines: 10,
            environment_name: false
          }
        }
      }

      app = App.new(name: "my_app")
      app.save

      expect(app.notice_fingerprinter.backtrace_lines).to eq(10)
      expect(app.notice_fingerprinter.environment_name).to eq(false)

      put :update, params: {
        site_config: {
          notice_fingerprinter_attributes: {
            backtrace_lines: 11,
            environment_name: true
          }
        }
      }

      app.reload

      expect(app.notice_fingerprinter.backtrace_lines).to eq(11)
      expect(app.notice_fingerprinter.environment_name).to eq(true)
    end
  end
end
