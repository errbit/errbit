describe AirbrakeApi::V3::NoticeParser do
  let(:app) { Fabricate(:app) }
  let(:notifier_params) do
    {
      "name"    => "notifiername",
      "version" => "notifierversion",
      "url"     => "notifierurl"
    }
  end

  it "raises error when errors attribute is missing" do
    expect do
      described_class.new({}).report
    end.to raise_error(AirbrakeApi::ParamsError)

    expect do
      described_class.new("errors" => []).report
    end.to raise_error(AirbrakeApi::ParamsError)
  end

  it "does not raise an error for the optional environment field" do
    expect do
      described_class.new("errors" => ["MyError"]).report
    end.not_to raise_error
  end

  it "parses JSON payload and returns ErrorReport" do
    params = build_params_for("api_v3_request.json", key: app.api_key)

    report = described_class.new(params).report
    notice = report.generate_notice!

    expect(report.error_class).to eq("Error")
    expect(report.message).to eq("Error: TestError")
    expect(report.backtrace.lines.size).to eq(9)
    expect(notice.user_attributes).to include(
      "id"       => 1,
      "name"     => "John Doe",
      "email"    => "john.doe@example.org",
      "username" => "john"
    )
    expect(notice.session).to include("isAdmin" => true)
    expect(notice.params).to include("returnTo" => "dashboard")
    expect(notice.env_vars).to include(
      "navigator_vendor" => "Google Inc.",
      "HTTP_USER_AGENT"  => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.99 Safari/537.36"
    )
  end

  it "parses JSON payload when api_key is missing but project_id is present" do
    params = build_params_for("api_v3_request.json", key: nil, project_id: app.api_key)

    report = described_class.new(params).report
    expect(report).to be_valid
  end

  it "parses JSON payload with missing backtrace" do
    json = Rails.root.join("spec", "fixtures", "api_v3_request_without_backtrace.json").read
    params = JSON.parse(json)
    params["key"] = app.api_key

    report = described_class.new(params).report
    report.generate_notice!

    expect(report.error_class).to eq("Error")
    expect(report.message).to eq("Error: TestError")
    expect(report.backtrace.lines.size).to eq(0)
  end

  it "parses JSON payload with deprecated user keys" do
    params = build_params_for("api_v3_request_with_deprecated_user_keys.json", key: app.api_key)

    report = AirbrakeApi::V3::NoticeParser.new(params).report
    notice = report.generate_notice!

    expect(notice.user_attributes).to include(
      "id"       => 1,
      "name"     => "John Doe",
      "email"    => "john.doe@example.org",
      "username" => "john"
    )
  end

  it "takes the notifier from root" do
    parser = described_class.new(
      "errors"      => ["MyError"],
      "notifier"    => notifier_params,
      "environment" => {})
    expect(parser.attributes[:notifier]).to eq(notifier_params)
  end

  it "takes the notifier from the context" do
    parser = described_class.new(
      "errors"      => ["MyError"],
      "context"     => { "notifier" => notifier_params },
      "environment" => {})
    expect(parser.attributes[:notifier]).to eq(notifier_params)
  end

  it "takes the hostname from the context" do
    parser = described_class.new(
      "errors"      => ["MyError"],
      "context"     => { "hostname" => "app01.infra.example.com", "url" => "http://example.com/some-page" },
      "environment" => {})
    expect(parser.attributes[:server_environment]["hostname"]).to eq("app01.infra.example.com")
  end

  describe "#user_attributes" do
    it "returns a user context hash" do
      user_hash = { id: 1, name: "John Doe" }
      parser = described_class.new("context" => { "user" => user_hash })
      expect(parser.send(:user_attributes)).to eq(user_hash)
    end

    it "returns a hash for a user context string" do
      user_string = "[Filtered]"
      parser = described_class.new("context" => { "user" => user_string })
      expect(parser.send(:user_attributes)).to eq(user: user_string)
    end
  end

  def build_params_for(fixture, options = {})
    json = Rails.root.join("spec", "fixtures", fixture).read
    data = JSON.parse(json)

    data["key"] = options[:key] if options.key?(:key)
    data["project_id"] = options[:project_id] if options.key?(:project_id)

    data
  end
end
