describe NoticeFingerprinter, type: "model" do
  let(:fingerprinter) { described_class.new }
  let(:notice) { Fabricate(:notice) }
  let(:backtrace) { Fabricate(:backtrace) }

  context "#generate" do
    it "generates the same fingerprint for the same notice" do
      f1 = fingerprinter.generate("123", notice, backtrace)
      f2 = fingerprinter.generate("123", notice, backtrace)
      expect(f1).to eq(f2)
    end

    %w(error_class message component action environment_name).each do |i|
      it "affects the fingerprint when #{i} is false" do
        f1 = fingerprinter.generate("123", notice, backtrace)
        f2 = fingerprinter.generate("123", notice, backtrace)

        fingerprinter.send((i << "=").to_sym, false)
        f3 = fingerprinter.generate("123", notice, backtrace)

        expect(f1).to eq(f2)
        expect(f1).to_not eq(f3)
      end
    end

    it "affects the fingerprint with different backtrace_lines config" do
      f1 = fingerprinter.generate("123", notice, backtrace)
      f2 = fingerprinter.generate("123", notice, backtrace)

      fingerprinter.backtrace_lines = 2
      f3 = fingerprinter.generate("123", notice, backtrace)

      expect(f1).to eq(f2)
      expect(f1).to_not eq(f3)
    end

    context "two backtraces have the same first two lines" do
      let(:backtrace1) { Fabricate(:backtrace) }
      let(:backtrace2) { Fabricate(:backtrace) }

      before do
        backtrace1.lines[0] = backtrace2.lines[0]
        backtrace1.lines[1] = backtrace2.lines[1]
        backtrace1.lines[2] = { number: 1, file: "a", method: :b }
      end

      it "has the same fingerprint when only considering two lines" do
        fingerprinter.backtrace_lines = 2
        f1 = fingerprinter.generate("123", notice, backtrace1)
        f2 = fingerprinter.generate("123", notice, backtrace2)

        expect(f1).to eq(f2)
      end

      it "has a different fingerprint when considering three lines" do
        fingerprinter.backtrace_lines = 3
        f1 = fingerprinter.generate("123", notice, backtrace1)
        f2 = fingerprinter.generate("123", notice, backtrace2)

        expect(f1).to_not eq(f2)
      end
    end

    context "two notices with no backtrace" do
      it "has the same fingerprint" do
        f1 = fingerprinter.generate("123", notice, nil)
        f2 = fingerprinter.generate("123", notice, nil)

        expect(f1).to eq(f2)
      end
    end
  end
end
