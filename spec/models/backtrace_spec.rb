require 'spec_helper'

describe Backtrace do
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
        expect(described_class).to receive(:create).with(attributes)

        described_class.find_or_create(attributes)
      end
    end

    context "similar backtrace exist" do
      let(:similar_backtrace) { double :similar_backtrace }
      before { backtrace.stub(:similar => similar_backtrace) }

      it { should == similar_backtrace }
    end
  end

  describe "#lines" do
    it "should return backtrace lines in the order they were received" do
      lines = (1..100).map { |i| line("[GEM_ROOT]/gems/activerecord-4.0.3/lib/active_record/relation.rb", i) }
      backtrace = Backtrace.create!(raw: lines)
      expect(backtrace.lines(true).pluck(:number)).to eq((1..100).to_a)
    end
  end

private

  def line(file, line_number, method="<method>")
    {"number" => line_number.to_s, "file" => file, "method" => method}
  end

end
