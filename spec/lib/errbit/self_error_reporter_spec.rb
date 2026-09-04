# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::SelfErrorReporter do
  let(:exception) do
    StandardError.new("self error").tap do |error|
      error.set_backtrace(["#{Rails.root}/app/models/error_report.rb:12:in `generate_notice!'"])
    end
  end

  after { Airbrake.reset }

  before do
    allow(described_class).to receive(:public_environment?).and_return(true)
  end

  ["development", "test"].each do |environment|
    it "does not report in #{environment}" do
      allow(described_class).to receive(:public_environment?).and_call_original
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(environment))

      expect(Airbrake).not_to receive(:build_notice)

      described_class.notify(exception)
    end
  end

  it "creates the Self.Errbit app when missing" do
    expect do
      described_class.notify(exception)
    end.to change { App.where(name: "Self.Errbit").count }.by(1)
  end

  it "reuses an existing Self.Errbit app without overwriting custom settings" do
    app = create(:app, name: "Self.Errbit", github_repo: "custom/repo")

    described_class.notify(exception)

    expect(app.reload.github_repo).to eq("custom/repo")
  end

  it "reuses the same Self.Errbit app for different exceptions" do
    described_class.notify(exception)
    described_class.notify(RuntimeError.new("another self error"))

    expect(App.where(name: "Self.Errbit").count).to eq(1)
  end

  it "creates a notice and problem for the exception" do
    expect do
      described_class.notify(exception)
    end.to change(Notice, :count).by(1)
      .and change(Problem, :count).by(1)

    notice = Notice.last
    expect(notice.error_class).to eq("StandardError")
    expect(notice.message).to include("self error")
  end

  it "passes the Self.Errbit app API key to the Airbrake v3 parser" do
    app = create(:app, name: "Self.Errbit")
    report = instance_double(ErrorReport, generate_notice!: true)
    parser = instance_double(AirbrakeApi::V3::NoticeParser, report: report)

    expect(AirbrakeApi::V3::NoticeParser).to receive(:new) do |payload|
      expect(payload["key"]).to eq(app.api_key)
      parser
    end

    described_class.notify(exception)
  end

  it "ignores Mongoid document not found errors" do
    exception = Mongoid::Errors::DocumentNotFound.new(App, {id: "missing"}, nil)

    expect(Airbrake).not_to receive(:build_notice)

    described_class.notify(exception)
  end

  it "does not invoke Airbrake delivery APIs" do
    expect(Airbrake).not_to receive(:notify)
    expect(Airbrake).not_to receive(:notify_sync)

    described_class.notify(exception)
  end

  describe described_class::Middleware do
    let(:env) { Rack::MockRequest.env_for("/") }

    it "reports exceptions stored by Rails and returns the response" do
      env["action_dispatch.exception"] = exception
      app = ->(_env) { [400, {}, []] }
      middleware = described_class.new(app)

      expect(described_class.superclass).to eq(Airbrake::Rack::Middleware)
      expect(Errbit::SelfErrorReporter).to receive(:notify).with(
        exception,
        request: instance_of(ActionDispatch::Request)
      )

      expect(middleware.call(env)).to eq([400, {}, []])
    end

    it "reports exceptions raised by the application and re-raises them" do
      app = ->(_env) { raise exception }
      middleware = described_class.new(app)

      expect(Errbit::SelfErrorReporter).to receive(:notify).with(
        exception,
        request: instance_of(ActionDispatch::Request)
      )

      expect { middleware.call(env) }.to raise_error(exception)
    end
  end

  it "does not parse a payload when Airbrake does not build a notice" do
    allow(Airbrake).to receive(:build_notice).and_return(nil)

    expect(AirbrakeApi::V3::NoticeParser).not_to receive(:new)

    described_class.notify(exception)
  end

  it "logs and swallows failures while reporting" do
    allow(AirbrakeApi::V3::NoticeParser).to receive(:new).and_raise(StandardError, "parser failed")

    expect(Rails.logger).to receive(:error).with("Errbit::SelfErrorReporter failed: StandardError - parser failed")

    expect do
      described_class.notify(exception)
    end.not_to raise_error
  end

  it "does not build a notice when the Self.Errbit app cannot be loaded" do
    allow(App).to receive(:where).and_raise(StandardError, "database unavailable")
    allow(Rails.logger).to receive(:error)

    expect(Airbrake).not_to receive(:build_notice)

    expect do
      described_class.notify(exception)
    end.not_to raise_error
  end
end
