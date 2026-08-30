# frozen_string_literal: true

require "rails_helper"
require "rake"

Rails.application.load_tasks

RSpec.describe "errbit:sanitize_historical_notices" do
  let(:task) { Rake::Task["errbit:sanitize_historical_notices"] }

  before do
    task.reenable
  end

  it "exits unsuccessfully when the service reports failures" do
    result = HistoricalNoticeSanitizer::Result.new(scanned: 1, changed: 0, unchanged: 0, failed: 1)
    sanitizer = instance_double(HistoricalNoticeSanitizer, run: result)
    allow(HistoricalNoticeSanitizer).to receive(:new).and_return(sanitizer)

    expect { task.invoke }.to raise_error(SystemExit)
  end

  it "defaults to dry run" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("DRY_RUN", "true").and_return("true")
    result = HistoricalNoticeSanitizer::Result.new(scanned: 0, changed: 0, unchanged: 0, failed: 0)
    sanitizer = instance_double(HistoricalNoticeSanitizer, run: result)
    expect(HistoricalNoticeSanitizer).to receive(:new).with(hash_including(dry_run: true)).and_return(sanitizer)

    task.invoke
  end

  it "enables writes only for exact lowercase false" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("DRY_RUN", "true").and_return("false")
    result = HistoricalNoticeSanitizer::Result.new(scanned: 0, changed: 0, unchanged: 0, failed: 0)
    sanitizer = instance_double(HistoricalNoticeSanitizer, run: result)
    expect(HistoricalNoticeSanitizer).to receive(:new).with(hash_including(dry_run: false)).and_return(sanitizer)

    task.invoke
  end

  it "keeps uppercase false in dry-run mode" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("DRY_RUN", "true").and_return("FALSE")
    result = HistoricalNoticeSanitizer::Result.new(scanned: 0, changed: 0, unchanged: 0, failed: 0)
    sanitizer = instance_double(HistoricalNoticeSanitizer, run: result)
    expect(HistoricalNoticeSanitizer).to receive(:new).with(hash_including(dry_run: true)).and_return(sanitizer)

    task.invoke
  end

  it "treats an empty limit as unset" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("LIMIT").and_return("")
    result = HistoricalNoticeSanitizer::Result.new(scanned: 0, changed: 0, unchanged: 0, failed: 0)
    sanitizer = instance_double(HistoricalNoticeSanitizer, run: result)
    expect(HistoricalNoticeSanitizer).to receive(:new).with(hash_including(limit: nil)).and_return(sanitizer)

    task.invoke
  end
end
