require 'spec_helper'

describe ErrorReport do
  context "with notice without line of backtrace" do
    let(:xml){
      Rails.root.join('spec','fixtures','hoptoad_test_notice_with_one_line_of_backtrace.xml').read
    }

    let(:error_report) {
      ErrorReport.new(xml)
    }

    let!(:app) {
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

    describe "#generate_notice!" do
      it "save a notice" do
        expect {
          error_report.generate_notice!
        }.to change {
          app.reload.problems.count
        }.by(1)
      end

      it 'memoize the notice' do
        expect {
          error_report.generate_notice!
          error_report.generate_notice!
        }.to change {
          Notice.count
        }.by(1)
      end
    end

    describe "#valid?" do
      context "with valid error report" do
        it "return true" do
          expect(error_report.valid?).to be true
        end
      end
      context "with not valid api_key" do
        before do
          App.where(:api_key => app.api_key).delete_all
        end
        it "return false" do
          expect(error_report.valid?).to be false
        end
      end
    end

    describe "#notice" do
      context "before generate_notice!" do
        it 'return nil' do
          expect(error_report.notice).to be nil
        end
      end

      context "after generate_notice!" do
        before do
          error_report.generate_notice!
        end

        it 'return the notice' do
          expect(error_report.notice).to be_a Notice
        end

      end
    end


  end
end
