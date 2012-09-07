require 'spec_helper'

describe "notices/_backtrace.html.haml" do
  describe 'missing file in backtrace' do
    let(:notice) do
      backtrace = { 'number' => rand(999), 'file' => nil, 'method' => ActiveSupport.methods.shuffle.first }
      Fabricate(:notice, :backtrace => [backtrace])
    end

    it "should replace nil file with [unknown source]" do
      assign :app, notice.err.app

      render "notices/backtrace", :lines => notice.backtrace
      rendered.should match(/\[unknown source\]/)
    end
  end
end

