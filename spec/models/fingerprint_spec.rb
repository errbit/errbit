require 'spec_helper'

describe Fingerprint do

  context '#generate' do
    let(:backtrace) {
      Backtrace.create(:raw => [
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
        expect(Fingerprint.generate(notice1, "api key")).to eq  Fingerprint.generate(notice2, "api key")
      end
    end

    context "with different backtrace with only last line change" do
      let(:backtrace_2) {
        backtrace
        backtrace.lines.last.number = 401
        backtrace.send(:generate_fingerprint)
        backtrace.save
        backtrace
      }
      it 'should not same fingerprint' do
        expect(
          Fingerprint.generate(notice1, "api key")
        ).not_to eql Fingerprint.generate(notice2, "api key")
      end
    end
  end

end

