require 'spec_helper'

describe "notices/_backtrace.html.haml" do
  describe 'missing file in backtrace' do
    before do
      @notice = Factory(:notice, :backtrace => [{
        'number'  => rand(999),
        'file'    => nil,
        'method'  => ActiveSupport.methods.shuffle.first
      }])
      assign :app, @notice.err.app
    end

    it "should replace nil file with [unknown source]" do
      render :partial => "notices/backtrace", :locals => {:lines => @notice.backtrace}
      rendered.should match(/\[unknown source\]/)
    end
  end
end

