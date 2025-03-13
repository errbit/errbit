describe HashHelper do
  describe ".pretty_hash" do
    let(:expected_pretty_hash) do
      <<~HASH.chomp
        {
          "action" => "some_action",
          "controller" => "some_controller"
        }
      HASH
    end

    it "is expected to prettify hashes" do
      expect(pretty_hash("controller" => "some_controller", "action" => "some_action")).to eq expected_pretty_hash
    end

    it "is expected to handle empty hashes" do
      expect(pretty_hash({})).to eq "{}"
    end

    context "with string, instead of hash" do
      it "is expected not to raise exception" do
        expect { pretty_hash("This is a string.") }.not_to raise_exception
      end

      it "is expected to handle strings" do
        expect(pretty_hash('{ a_string: "But it looks like a hash"}')).to eq "{}"
      end
    end
  end
end
