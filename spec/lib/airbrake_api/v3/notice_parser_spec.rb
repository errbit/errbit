describe AirbrakeApi::V3::NoticeParser do
  let(:app) { Fabricate(:app) }

  it 'raises error when errors attribute is missing' do
    expect {
      AirbrakeApi::V3::NoticeParser.new({}).report
    }.to raise_error(AirbrakeApi::ParamsError)

    expect {
      AirbrakeApi::V3::NoticeParser.new({'errors' => []}).report
    }.to raise_error(AirbrakeApi::ParamsError)
  end

  it 'parses JSON payload and returns ErrorReport' do
    params = build_params(key: app.api_key)

    report = AirbrakeApi::V3::NoticeParser.new(params).report
    notice = report.generate_notice!

    expect(report.error_class).to eq('Error')
    expect(report.message).to eq('Error: TestError')
    expect(report.backtrace.lines.size).to eq(9)
    expect(notice.user_attributes).to include({'Id' => 1, 'Name' => 'John Doe', 'Email' => 'john.doe@example.org', 'Username' => 'john'})
    expect(notice.session).to include('isAdmin' => true)
    expect(notice.params).to include('returnTo' => 'dashboard')
    expect(notice.env_vars).to include(
      'navigator_vendor' => 'Google Inc.',
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.99 Safari/537.36'
    )
  end

  it 'parses JSON payload when api_key is missing but project_id is present' do
    params = build_params(key: nil, project_id: app.api_key)

    report = AirbrakeApi::V3::NoticeParser.new(params).report
    expect(report).to be_valid
  end

  it 'parses JSON payload with missing backtrace' do
    json = Rails.root.join('spec', 'fixtures', 'api_v3_request_without_backtrace.json').read
    params = JSON.parse(json)
    params['key'] = app.api_key

    report = AirbrakeApi::V3::NoticeParser.new(params).report
    notice = report.generate_notice!

    expect(report.error_class).to eq('Error')
    expect(report.message).to eq('Error: TestError')
    expect(report.backtrace.lines.size).to eq(0)
  end

  def build_params(options = {})
    json = Rails.root.join('spec', 'fixtures', 'api_v3_request.json').read
    data = JSON.parse(json)

    data['key'] = options[:key] if options.has_key?(:key)
    data['project_id'] = options[:project_id] if options.has_key?(:project_id)

    data
  end
end