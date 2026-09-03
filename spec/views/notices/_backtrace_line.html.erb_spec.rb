# frozen_string_literal: true

require "rails_helper"

RSpec.describe "notices/_backtrace_line.html.erb", type: :view do
  let(:line) do
    instance_double(
      BacktraceLineDecorator,
      decorated_path: "gems/foo/<strong>bar</strong><script>alert(1)</script><img src=x onerror=alert(1)>",
      file_name: "example.rb",
      in_app?: false,
      method: "call",
      number: nil,
      column: nil
    )
  end

  before do
    allow(line).to receive(:link_to_source_file) { |&block| view.capture(&block) }
    render partial: "notices/backtrace_line", locals: {line: line, app: double}
  end

  it "preserves gem highlighting" do
    expect(rendered).to include("gems/foo/<strong>bar</strong>")
  end

  it "removes unsafe markup and attributes" do
    expect(rendered).not_to include("<script>")
    expect(rendered).not_to include("onerror=")
    expect(rendered).not_to include("<img")
  end
end
