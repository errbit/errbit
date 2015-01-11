describe Backtrace, type: 'model' do
  subject { described_class.new }

  its(:fingerprint) { should be_present }

  describe "#similar" do
    context "no similar backtrace" do
      its(:similar) { should be_nil }
    end

    context "similar backtrace exist" do
      let!(:similar_backtrace) {
        b =  Fabricate(:backtrace)
        b.fingerprint = fingerprint
        b.save!
        b
      }
      let(:fingerprint) { "fingerprint" }

      before { allow(subject).to receive(:fingerprint).and_return(fingerprint) }

      its(:similar) { should == similar_backtrace }
    end
  end

  describe "find_or_create" do
    subject { described_class.find_or_create(attributes) }
    let(:attributes) { double :attributes }
    let(:backtrace) { double :backtrace }

    before { allow(described_class).to receive(:new).and_return(backtrace) }

    context "no similar backtrace" do
      before { allow(backtrace).to receive(:similar).and_return(nil) }
      it "create new backtrace" do
        expect(described_class).to receive(:create).with(attributes)

        described_class.find_or_create(attributes)
      end
    end

    context "similar backtrace exist" do
      let(:similar_backtrace) { double :similar_backtrace }
      before { allow(backtrace).to receive(:similar).and_return(similar_backtrace) }

      it { should == similar_backtrace }
    end
  end
end
