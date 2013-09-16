require 'spec_helper'

describe Backtrace do
  subject { described_class.new }

  its(:fingerprint) { should be_present }

  describe "#similar" do
    context "no similar backtrace" do
      its(:similar) { should be_nil }
    end

    context "similar backtrace exist" do
      let!(:similar_backtrace) { Fabricate(:backtrace, :fingerprint => fingerprint) }
      let(:fingerprint) { "fingerprint" }

      before { subject.stub(:fingerprint => fingerprint) }

      its(:similar) { should == similar_backtrace }
    end
  end

  describe "find_or_create" do
    subject { described_class.find_or_create(attributes) }
    let(:attributes) { double :attributes }
    let(:backtrace) { double :backtrace }

    before { described_class.stub(:new => backtrace) }

    context "no similar backtrace" do
      before { backtrace.stub(:similar => nil) }
      it "create new backtrace" do
        described_class.should_receive(:create).with(attributes)

        described_class.find_or_create(attributes)
      end
    end

    context "similar backtrace exist" do
      let(:similar_backtrace) { double :similar_backtrace }
      before { backtrace.stub(:similar => similar_backtrace) }

      it { should == similar_backtrace }
    end
  end
end
