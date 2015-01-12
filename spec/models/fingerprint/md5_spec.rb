describe Fingerprint::MD5, type: 'model' do
  context 'being created' do
    let(:backtrace) do
      Backtrace.create(:raw => [
        {
          "number"=>"17",
          "file"=>"[GEM_ROOT]/gems/activesupport/lib/active_support/callbacks.rb",
          "method"=>"_run__2497084960985961383__process_action__2062871603614456254__callbacks"
        }
      ])
    end
    let(:notice1) { Fabricate.build(:notice, :backtrace => backtrace) }
    let(:notice2) { Fabricate.build(:notice, :backtrace => backtrace_2) }

    context "with same backtrace" do
      let(:backtrace_2) do
        backtrace
        backtrace.lines.last.method =  '_run__FRAGMENT__process_action__FRAGMENT__callbacks'
        backtrace.save
        backtrace
      end

      it "normalizes the fingerprint of generated methods" do
        expect(Fingerprint::MD5.generate(notice1, "api key")).to eql Fingerprint::MD5.generate(notice2, "api key")
      end
    end

    context "with same backtrace where FRAGMENT has not been extracted" do
      let(:backtrace_2) do
        backtrace
        backtrace.lines.last.method =  '_run__998857585768765__process_action__1231231312321313__callbacks'
        backtrace.save
        backtrace
      end

      it "normalizes the fingerprint of generated methods" do
        expect(Fingerprint::MD5.generate(notice1, "api key")).to eql Fingerprint::MD5.generate(notice2, "api key")
      end
    end
  end
end
