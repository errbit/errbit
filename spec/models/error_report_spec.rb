require 'spec_helper'

describe ErrorReport do
  context "with notice without line of backtrace" do
    let(:xml){
      Rails.root.join('spec','fixtures','hoptoad_test_notice_with_one_line_of_backtrace.xml').read
    }

    let(:error_report) {
      ErrorReport.new(xml)
    }

    let(:app) {
      Fabricate(
        :app,
        :api_key => 'APIKEY'
      )
    }

    describe "#backtrace" do

      it 'should have valid backtrace' do
        error_report.backtrace.should be_valid
      end
    end

    context "#generate_notice!" do
      it "save a notice" do
        expect {
          error_report.generate_notice!
        }.to change {
          app.reload.problems.count
        }.by(1)
      end
    end
  end
end
