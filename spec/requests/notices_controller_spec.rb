describe "Notices management", type: "request" do
  let(:errbit_app) { Fabricate(:app, api_key: "APIKEY") }

  describe "create a new notice" do
    context "with valide notice" do
      let(:xml) { Rails.root.join("spec", "fixtures", "hoptoad_test_notice.xml").read }
      it "save a new notice" do
        expect do
          post "/notifier_api/v2/notices", params: { data: xml }
          expect(response).to be_successful
        end.to change {
          errbit_app.problems.count
        }.by(1)
      end
    end

    context "with notice with empty backtrace" do
      let(:xml) { Rails.root.join("spec", "fixtures", "hoptoad_test_notice_without_line_of_backtrace.xml").read }
      it "save a new notice" do
        expect do
          post "/notifier_api/v2/notices", params: { data: xml }
          expect(response).to be_successful
        end.to change {
          errbit_app.problems.count
        }.by(1)
      end
    end

    context "with notice with bad api_key" do
      let(:errbit_app) { Fabricate(:app) }
      let(:xml) { Rails.root.join("spec", "fixtures", "hoptoad_test_notice.xml").read }
      it "not save a new notice and return 422" do
        expect do
          post "/notifier_api/v2/notices", params: { data: xml }
          expect(response.status).to eq 422
          expect(response.body).to eq "Your API key is unknown"
        end.to_not change(errbit_app.problems, :count)
      end
    end

    context "with GET request" do
      let(:xml) { Rails.root.join("spec", "fixtures", "hoptoad_test_notice.xml").read }
      it "save a new notice" do
        expect do
          get "/notifier_api/v2/notices", params: { data: xml }
          expect(response).to be_successful
        end.to change {
          errbit_app.problems.count
        }.by(1)
      end
    end
  end
end
