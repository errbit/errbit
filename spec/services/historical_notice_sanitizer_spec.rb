# frozen_string_literal: true

require "rails_helper"

RSpec.describe HistoricalNoticeSanitizer, type: :model do
  def legacy_notice
    allow(Errbit::Config).to receive(:sanitize_notice_data).and_return(false)
    create(:notice,
      request: {
        "params" => {"password" => "secret", "safe" => "value"},
        "session" => {"csrf_token" => "secret", "locale" => "en"}
      },
      notifier: {"authorization" => "secret"})
  end

  it "scrubs existing notices with privacy enabled regardless of current config" do
    notice = legacy_notice
    notice.reload
    updated_at = notice.updated_at

    result = described_class.new(scope: Notice.where(id: notice.id), dry_run: false).run

    expect(result).to eq(described_class::Result.new(scanned: 1, changed: 1, unchanged: 0, failed: 0))
    notice.reload
    expect(notice.params).to eq("password" => Notice::FILTERED_TEXT, "safe" => "value")
    expect(notice.session).to eq("csrf_token" => Notice::FILTERED_TEXT, "locale" => "en")
    expect(notice.notifier).to eq("authorization" => Notice::FILTERED_TEXT)
    expect(notice.updated_at).to eq(updated_at)
  end

  it "does not write during a dry run" do
    notice = legacy_notice

    result = described_class.new(scope: Notice.where(id: notice.id)).run

    expect(result).to eq(described_class::Result.new(scanned: 1, changed: 1, unchanged: 0, failed: 0))
    notice.reload
    expect(notice.params["password"]).to eq("secret")
  end

  it "is idempotent" do
    notice = legacy_notice
    sanitizer = described_class.new(scope: Notice.where(id: notice.id), dry_run: false)

    sanitizer.run
    result = sanitizer.run

    expect(result).to eq(described_class::Result.new(scanned: 1, changed: 0, unchanged: 1, failed: 0))
  end

  it "honors a limit" do
    notices = 2.times.map { legacy_notice }

    result = described_class.new(scope: Notice.where(:id.in => notices.map(&:id)), limit: 1, dry_run: false).run

    expect(result.scanned).to eq(1)
    expect(Notice.where(:id.in => notices.map(&:id)).where("request.params.password" => "secret").count).to eq(1)
  end

  it "continues after a notice fails and does not log its contents" do
    failing_notice = instance_double(Notice, id: "failed-id")
    allow(failing_notice).to receive(:sanitized_attributes).and_raise(StandardError, "secret-value")
    unchanged_notice = instance_double(
      Notice,
      id: "unchanged-id",
      attributes: {
        "server_environment" => nil,
        "request" => nil,
        "notifier" => nil,
        "user_attributes" => nil
      },
      sanitized_attributes: {
        "server_environment" => nil,
        "request" => nil,
        "notifier" => nil,
        "user_attributes" => nil
      }
    )
    scope = double
    allow(scope).to receive(:order_by).and_return(scope)
    allow(scope).to receive(:batch_size).and_return(scope)
    allow(scope).to receive(:each).and_yield(failing_notice).and_yield(unchanged_notice)
    logger = instance_double(Logger)
    expect(logger).to receive(:error).with("Historical notice sanitization failed for failed-id: StandardError")

    result = described_class.new(scope: scope, logger: logger).run

    expect(result).to eq(described_class::Result.new(scanned: 2, changed: 0, unchanged: 1, failed: 1))
  end

  it "counts a notice that disappears before update as a failure" do
    notice = legacy_notice
    collection = Notice.collection
    allow(Notice).to receive(:collection).and_return(collection)
    allow(collection).to receive(:find_one_and_update).and_return(nil)
    logger = instance_double(Logger)
    expect(logger).to receive(:error).with("Historical notice sanitization failed for #{notice.id}: notice no longer exists")

    result = described_class.new(scope: Notice.where(id: notice.id), dry_run: false, logger: logger).run

    expect(result.scanned).to eq(1)
    expect(result.changed).to eq(0)
    expect(result.unchanged).to eq(0)
    expect(result.failed).to eq(1)
  end

  it "requires a positive batch size and limit" do
    expect { described_class.new(batch_size: 0) }.to raise_error(ArgumentError, "batch size must be positive")
    expect { described_class.new(limit: 0) }.to raise_error(ArgumentError, "limit must be positive")
  end
end
