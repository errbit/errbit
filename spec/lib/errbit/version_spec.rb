describe Errbit::VERSION do
  subject { Errbit::Version.new.full_version }

  it 'handles a missing commit sha' do
    allow(ENV).to receive(:[]).with('SOURCE_VERSION') { nil }
    expect(subject).to end_with('dev')
  end

  it 'shortens a present commit sha' do
    allow(ENV).to receive(:[]).with('SOURCE_VERSION') { 'abcd1234efgh56789' }
    expect(subject).to end_with('dev-abcd1234')
  end
end
