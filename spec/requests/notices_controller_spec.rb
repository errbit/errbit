require 'spec_helper'

describe "Notices management" do

  let(:errbit_app) { Fabricate(:app,
                       :api_key => 'APIKEY') }

  describe "create a new notice" do
    context "with valide notice" do
      let(:xml) { Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read }
      it 'save a new notice' do
        expect {
          post '/notifier_api/v2/notices', :data => xml
          expect(response).to be_success
        }.to change {
          errbit_app.problems.count
        }.by(1)
      end
    end

    context "with notice with empty backtrace" do
      let(:xml) { Rails.root.join('spec','fixtures','hoptoad_test_notice_without_line_of_backtrace.xml').read }
      it 'save a new notice' do
        expect {
          post '/notifier_api/v2/notices', :data => xml
          expect(response).to be_success
        }.to change {
          errbit_app.problems.count
        }.by(1)
      end
    end

  end

end
