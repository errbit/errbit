describe BacktraceLineDecorator, type: :decorator do
  let(:backtrace_line) do
    described_class.new(
      number: 884,
      file: '/path/to/file/ea315ea4.rb',
      method: :instance_eval)
  end
  let(:backtrace_line_in_app) do
    described_class.new(
      number: 884,
      file: '[PROJECT_ROOT]/path/to/file/ea315ea4.rb',
      method: :instance_eval)
  end
  let(:app) { Fabricate(:app, github_repo: 'foo/bar') }

  describe '#to_s' do
    it 'returns a nice string representation of the first line' do
      expect(backtrace_line.to_s).to eq('/path/to/file/ea315ea4.rb:884')
    end
  end

  describe '#link_to_source_file' do
    it 'adds a link to the source file' do
      link = backtrace_line_in_app.link_to_source_file(app) { 'mytext' }
      expect(link).to eq(
        '<a target="_blank" href="https://github.com/foo/bar/blob/master/pat' \
        'h/to/file/ea315ea4.rb#L884">mytext</a>')
    end
  end
end
