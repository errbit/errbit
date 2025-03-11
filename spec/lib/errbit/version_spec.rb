describe Errbit::Version do
  let(:version) { '0.0.0' }

  context "release version" do
    subject { Errbit::Version.new(version).full_version }

    it 'generates a release version' do
      expect(subject).to eq(version)
    end

    it 'does not use a commit sha' do
      allow(ENV).to receive(:[]).with('SOURCE_VERSION') { 'abcd1234efgh56789' }
      expect(subject).to eq(version)
    end
  end

  context "dev version" do
    subject { Errbit::Version.new(version, true).full_version }

    it 'generates a dev version' do
      expect(subject).to end_with('dev')
    end

    it 'handles a missing commit sha' do
      allow(ENV).to receive(:[]).with('SOURCE_VERSION') { nil }
      expect(subject).to end_with('dev')
    end

    it 'shortens a present commit sha' do
      allow(ENV).to receive(:[]).with('SOURCE_VERSION') { 'abcd1234efgh56789' }
      expect(subject).to end_with('dev-abcd1234')
    end
  end
end
