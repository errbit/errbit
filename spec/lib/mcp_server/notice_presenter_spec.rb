# frozen_string_literal: true

require "rails_helper"

RSpec.describe McpServer::NoticePresenter do
  let(:notice) do
    create(
      :notice,
      message: "m" * 600,
      error_class: "e" * 600,
      framework: "f" * 600,
      server_environment: {"environment-name" => "n" * 600, "app-version" => "v" * 600},
      request: {"component" => "c" * 600}
    )
  end

  before { allow(notice).to receive(:host).and_return("h" * 600) }

  it "bounds every string in notice summaries" do
    expect(described_class.summary(notice).values_at(:message, :error_class, :framework, :environment, :app_version, :where, :host).map(&:length)).to all(eq(500))
  end
end
