require 'spec_helper'

describe Fingerprint do

  context '#generate' do
    before do
      @backtrace = Backtrace.find_or_create(:raw => [
        {"number"=>"425", "file"=>"[GEM_ROOT]/gems/activesupport-3.0.0.rc/lib/active_support/callbacks.rb", "method"=>"_run__2115867319__process_action__262109504__callbacks"},
        {"number"=>"404", "file"=>"[GEM_ROOT]/gems/activesupport-3.0.0.rc/lib/active_support/callbacks.rb", "method"=>"send"},
        {"number"=>"404", "file"=>"[GEM_ROOT]/gems/activesupport-3.0.0.rc/lib/active_support/callbacks.rb", "method"=>"_run_process_action_callbacks"}
      ])
    end
    
    it 'should create the same fingerprint for two notices with the same backtrace' do
      notice1 = Fabricate.build(:notice, :backtrace => @backtrace)
      notice2 = Fabricate.build(:notice, :backtrace => @backtrace)
      
      Fingerprint.generate(notice1, "api key").should == Fingerprint.generate(notice2, "api key")
    end
  end

end

