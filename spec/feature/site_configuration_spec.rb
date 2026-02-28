# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin manages site configuration", type: :feature, retry: 3 do
  let!(:admin) { create(:user, admin: true) }

  before { sign_in(admin) }

  it "views the config page" do
    visit site_config_index_path

    expect(page).to have_content(/notice fingerprinter/i)
    expect(page).to have_field(I18n.t("shared.notice_fingerprinter.error_class"))
  end

  it "updates the configuration" do
    visit site_config_index_path

    click_button I18n.t("site_config.index.update_config")

    expect(page).to have_content(I18n.t("site_config.update.success"))
  end
end
