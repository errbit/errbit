require 'spec_helper'

describe BacktraceLineHelper do
  describe "in app lines" do
    let(:notice) do
      Fabricate.build(:notice, :backtrace =>
        Fabricate.build(:backtrace, :lines => [
          Fabricate.build(:backtrace_line, :file => "[PROJECT_ROOT]/path/to/asset.js")
        ])
      )
    end

    describe '#link_to_source_file' do
      it 'still returns text for in app file and line number when no repo is configured' do
        result = link_to_source_file(notice.backtrace.lines.first) { haml_concat "link text" }
        result.strip.should == 'link text'
      end
    end
  end
end
