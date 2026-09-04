# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1", type: :request do
  before do
    allow(Errbit::SelfErrorReporter).to receive(:public_environment?).and_return(true)
  end

  it "self-reports an unhandled API V1 exception" do
    user = create(:user)
    notice_count = Notice.count
    allow(Notice).to receive(:where).and_raise(RuntimeError, "database query failed")

    expect do
      get "/api/v1/notices", params: {auth_token: user.authentication_token}
    end.to raise_error(RuntimeError, "database query failed")

    expect(Notice.count).to eq(notice_count + 1)

    notice = Notice.last
    expect(notice.error_class).to eq("RuntimeError")
    expect(notice.request).to include(
      "component" => "notices",
      "action" => "index"
    )
    expect(notice.request["url"]).to include("/api/v1/notices")
    expect(notice.backtrace.lines).to be_present
  end
end
