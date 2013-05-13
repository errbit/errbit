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

    context "with notice with bad api_key" do
      let(:errbit_app) { Fabricate(:app) }
      let(:xml) { Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read }
      it 'not save a new notice and return 422' do
        expect {
          post '/notifier_api/v2/notices', :data => xml
          expect(response.status).to eq 422
          expect(response.body).to eq "Your API key is unknown"
        }.to_not change {
          errbit_app.problems.count
        }.by(1)
      end

    end

  end

end
