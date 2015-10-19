describe Fingerprint::Sha1, type: 'model' do
  context '#generate' do
    let(:backtrace) {
      Backtrace.find_or_create([
        {"number"=>"425", "file"=>"[GEM_ROOT]/gems/activesupport-3.0.0.rc/lib/active_support/callbacks.rb", "method"=>"_run__2115867319__process_action__262109504__callbacks"},
        {"number"=>"404", "file"=>"[GEM_ROOT]/gems/activesupport-3.0.0.rc/lib/active_support/callbacks.rb", "method"=>"send"},
        {"number"=>"404", "file"=>"[GEM_ROOT]/gems/activesupport-3.0.0.rc/lib/active_support/callbacks.rb", "method"=>"_run_process_action_callbacks"}
      ])
    }
    let(:notice1) { Fabricate.build(:notice, :backtrace => backtrace) }
    let(:notice2) { Fabricate.build(:notice, :backtrace => backtrace_2) }

    context "with same backtrace" do
      let(:backtrace_2) { backtrace }
      it 'should create the same fingerprint for two notices' do
        expect(Fingerprint::Sha1.generate(notice1, "api key")).to eq  Fingerprint::Sha1.generate(notice2, "api key")
      end
    end

    context "with different backtrace with only last line change" do
      let(:backtrace_2) {
        new_lines = backtrace.lines.dup
        new_lines.last[:number] = 401
        Backtrace.find_or_create backtrace.lines
      }
      it 'should not same fingerprint' do
        expect(
          Fingerprint::Sha1.generate(notice1, "api key")
        ).not_to eql Fingerprint::Sha1.generate(notice2, "api key")
      end
    end

    context 'with messages differing in object string memory addresses' do
      let(:backtrace_2) { backtrace }

      before do
        notice1.message = "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfe3287e8>"
        notice2.message = "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfd9f5338>"
      end

      its 'fingerprints should be equal' do
        expect(Fingerprint::Sha1.generate(notice1, 'api key')).to eq Fingerprint::Sha1.generate(notice2, 'api key')
      end
    end

    context 'with different messages at same stacktrace' do
      let(:backtrace_2) { backtrace }

      before do
        notice1.message = "NoMethodError: undefined method `bar' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfe3287e8>"
        notice2.message = "NoMethodError: undefined method `bar' for nil:NilClass"
      end

      its 'fingerprints should not be equal' do
        expect(Fingerprint::Sha1.generate(notice1, 'api key')).to_not eq Fingerprint::Sha1.generate(notice2, 'api key')
      end
    end
  end

  describe '#unified_message' do
    subject{ Fingerprint::Sha1.new(double('notice', message: message), 'api key').unified_message }

    context "full error message" do
      let(:message) { "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfe3287e8>" }

      it 'removes memory address from object strings' do
        is_expected.to eq "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess>"
      end
    end

    context "multiple object strings in message" do
      let(:message) { "#<ActiveSupport::HashWithIndifferentAccess:0x007f6bfe3287e8> #<Object:0x007fa2b33d9458>" }

      it 'removes memory addresses globally' do
        is_expected.to eq "#<ActiveSupport::HashWithIndifferentAccess> #<Object>"
      end
    end
  end
end
