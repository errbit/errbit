describe Backtrace, type: "model" do
  describe ".find_or_create" do
    let(:lines) do
      [
        { "number" => "123", "file" => "/some/path/to.rb", "method" => "abc" },
        { "number" => "345", "file" => "/path/to.rb", "method" => "dowhat" }
      ]
    end
    let(:fingerprint) { Backtrace.generate_fingerprint(lines) }

    it "create new backtrace" do
      backtrace = described_class.find_or_create(lines)

      expect(backtrace.lines).to eq(lines)
      expect(backtrace.fingerprint).to eq(fingerprint)
    end

    it "creates one backtrace for two identical ones" do
      described_class.find_or_create(lines)
      described_class.find_or_create(lines)

      expect(Backtrace.where(fingerprint: fingerprint).count).to eq(1)
    end
  end
end
