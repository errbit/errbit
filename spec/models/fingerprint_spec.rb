require "spec_helper"

describe Fingerprint do
  let(:app_id) { "<app.id>" }

  context "for two notices" do
    let(:backtrace) {
      Backtrace.create(:raw => [
        {"number"=>"425", "file"=>"[GEM_ROOT]/gems/activesupport-3.0.0.rc/lib/active_support/callbacks.rb", "method"=>"_run__2115867319__process_action__262109504__callbacks"},
        {"number"=>"404", "file"=>"[GEM_ROOT]/gems/activesupport-3.0.0.rc/lib/active_support/callbacks.rb", "method"=>"send"},
        {"number"=>"404", "file"=>"[GEM_ROOT]/gems/activesupport-3.0.0.rc/lib/active_support/callbacks.rb", "method"=>"_run_process_action_callbacks"}
      ])
    }
    let(:notice1) { Fabricate.build(:notice, :backtrace => backtrace) }
    let(:notice2) { Fabricate.build(:notice, :backtrace => backtrace_2) }
    let(:fingerprint1) { Fingerprint.generate(notice1, app_id) }
    let(:fingerprint2) { Fingerprint.generate(notice2, app_id) }

    context "with the same backtrace" do
      let(:backtrace_2) { backtrace }

      context "and the same messages" do
        it "should be the same" do
          expect(fingerprint1).to eq(fingerprint2)
        end
      end

      context "and messages that differ only in memory addresses" do
        before do
          notice1.message = "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfe3287e8>"
          notice2.message = "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfd9f5338>"
        end

        it "should be the same" do
          expect(fingerprint1).to eq(fingerprint2)
        end
      end

      context "but different messages" do
        before do
          notice1.message = "NoMethodError: undefined method `bar' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfe3287e8>"
          notice2.message = "NoMethodError: undefined method `bar' for nil:NilClass"
        end

        it "should not be the same" do
          expect(fingerprint1).not_to eq(fingerprint2)
        end
      end
    end

    context "with different backtraces" do
      let(:backtrace_2) {
        backtrace
        backtrace.lines.last.number = 401
        backtrace.send(:generate_fingerprint)
        backtrace.save
        backtrace
      }

      it "should not be the same" do
        expect(fingerprint1).not_to eq(fingerprint2)
      end
    end

  end

  describe '#unified_message' do
    subject { Fingerprint.new(double("notice", message: message), app_id).unified_message }

    context "given objects with memory addresses" do
      let(:message) { "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess:0x007f6bfe3287e8> #<Object:0x007fa2b33d9458>" }

      it "removes the memory addresses from all object strings" do
        should eq "NoMethodError: undefined method `foo' for #<ActiveSupport::HashWithIndifferentAccess> #<Object>"
      end
    end
  end

end
