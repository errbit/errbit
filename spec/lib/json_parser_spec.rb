describe JsonParser do
  let(:app) { Fabricate(:app) }

  it 'raises error when errors attribute is missing' do
    expect {
      JsonParser.new({}).report
    }.to raise_error(JsonParser::ParamsError)

    expect {
      JsonParser.new({'errors' => []}).report
    }.to raise_error(JsonParser::ParamsError)
  end

  it 'parses JSON payload and returns ErrorReport' do
    params = JSON.parse(<<-EOL)
      {
        "notifier":{"name":"airbrake-js-v8","version":"0.3.10","url":"https://github.com/airbrake/airbrake-js"},
        "errors":[
          {
            "type":"Error",
            "message":"Error: TestError",
            "backtrace":[
              {"function":"d","file":"http://localhost:3000/assets/application.js","line":11234,"column":24},
              {"function":"c","file":"http://localhost:3000/assets/application.js","line":11233,"column":18},
              {"function":"b","file":"http://localhost:3000/assets/application.js","line":11232,"column":18},
              {"function":"a","file":"http://localhost:3000/assets/application.js","line":11231,"column":18},
              {"function":"HTMLDocument.<anonymous>","file":"http://localhost:3000/assets/application.js","line":11236,"column":3},
              {"function":"fire","file":"http://localhost:3000/assets/application.js","line":1018,"column":34},
              {"function":"Object.self.fireWith [as resolveWith]","file":"http://localhost:3000/assets/application.js","line":1128,"column":13},
              {"function":"Function.jQuery.extend.ready","file":"http://localhost:3000/assets/application.js","line":417,"column":15},
              {"function":"HTMLDocument.DOMContentLoaded","file":"http://localhost:3000/assets/application.js","line":93,"column":14}
            ]
          }
        ],
        "context":{
          "language":"JavaScript",
          "sourceMapEnabled":true,
          "userAgent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.99 Safari/537.36",
          "url":"http://localhost:3000/kontakt",
          "userId":1,"userUsername":"john",
          "userName":"John Doe",
          "userUsername": "john",
          "userEmail":"john.doe@example.org",
          "version":"1.0",
          "component":"ContactsController",
          "action":"show"
        },
        "params":{"returnTo":"dashboard"},
        "environment":{"navigator_vendor":"Google Inc."},
        "session":{"isAdmin":true},
        "key":"#{app.api_key}"
      }
    EOL

    report = JsonParser.new(params).report
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
end