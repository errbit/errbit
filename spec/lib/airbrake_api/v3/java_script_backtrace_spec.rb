describe AirbrakeApi::V3::JavaScriptBacktrace do
  let(:backtrace) { described_class.new(lines) }
  let(:lines) { JSON.parse(Rails.root.join('spec', 'fixtures', 'api_v3_request.json').read)['errors'].first['backtrace'] }
  let(:file) { lines.first['file'] }

  describe '#normalized_lines' do
    subject { backtrace.normalized_lines }

    let(:source_map) { double }
    let(:remote_js_file) { double(source_map: source_map) }
    let(:normalized_line) { { 'is' => 'normalized' } }

    before do
      allow(AirbrakeApi::V3::RemoteJsFile).to receive(:new).with(file).and_return(remote_js_file)
      allow(source_map).to receive(:original_line).with(hash_including('file' => file)).and_return(normalized_line)
    end

    it 'returns normalized backtrace' do
      expect(subject.size).to eq lines.size
      expect(subject).to include(normalized_line)
    end
  end
end
