# frozen_string_literal: true

require "rails_helper"

RSpec.describe McpServer::ProblemPresenter do
  let(:problem) do
    create(
      :problem,
      app_name: "a" * 600,
      message: "m" * 600,
      environment: "n" * 600,
      error_class: "e" * 600,
      where: "w" * 600,
      issue_link: "i" * 600
    )
  end
  let(:summary) { described_class.summary(problem) }
  let(:detail) { described_class.detail(problem) }

  before do
    allow(problem).to receive(:app_name).and_return("a" * 600)
    allow(problem).to receive(:url).and_return("u" * 600)
  end

  it "bounds every string in problem summaries and details" do
    expect((summary.values_at(:app_name, :message, :url, :environment, :error_class, :where) + [detail.fetch(:issue_link)]).map(&:length)).to all(eq(500))
  end
end
