require 'spec_helper'

describe NoticesController do
  it_requires_authentication :for => { :locate => :get }

  let(:notice) { Fabricate(:notice) }
  let(:xml) { Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read }
  let(:app) { Fabricate(:app) }
  let(:error_report) { double(:valid? => true, :generate_notice! => true, :notice => notice) }

  context 'notices API' do
    context "with all params" do
      before do
        expect(ErrorReport).to receive(:new).with(xml).and_return(error_report)
      end

      context "with xml pass in raw_port" do
        before do
          expect(request).to receive(:raw_post).and_return(xml)
          post :create, :format => :xml
        end

        it "generates a notice from raw xml [POST]" do
          expect(response).to be_success
          # Same RegExp from Airbrake::Sender#send_to_airbrake (https://github.com/airbrake/airbrake/blob/master/lib/airbrake/sender.rb#L53)
          # Inspired by https://github.com/airbrake/airbrake/blob/master/test/sender_test.rb
          expect(response.body).to match(%r{<id[^>]*>#{notice.id}</id>})
          expect(response.body).to match(%r{<url[^>]*>(.+)#{locate_path(notice.id)}</url>})
        end

      end

      it "generates a notice from xml in a data param [POST]" do
        post :create, :data => xml, :format => :xml
        expect(response).to be_success
        # Same RegExp from Airbrake::Sender#send_to_airbrake (https://github.com/airbrake/airbrake/blob/master/lib/airbrake/sender.rb#L53)
        # Inspired by https://github.com/airbrake/airbrake/blob/master/test/sender_test.rb
        expect(response.body).to match(%r{<id[^>]*>#{notice.id}</id>})
        expect(response.body).to match(%r{<url[^>]*>(.+)#{locate_path(notice.id)}</url>})
      end

      it "generates a notice from xml [GET]" do
        get :create, :data => xml, :format => :xml
        expect(response).to be_success
        expect(response.body).to match(%r{<id[^>]*>#{notice.id}</id>})
        expect(response.body).to match(%r{<url[^>]*>(.+)#{locate_path(notice.id)}</url>})
      end
      context "with an invalid API_KEY" do
        let(:error_report) { double(:valid? => false) }
        it 'return 422' do
          post :create, :format => :xml, :data => xml
          expect(response.status).to eq 422
        end
      end
    end

    context "without params needed" do
      it 'return 400' do
        post :create, :format => :xml
        expect(response.status).to eq 400
        expect(response.body).to eq 'Need a data params in GET or raw post data'
      end
    end
  end

  describe "GET /locate/:id" do
    context 'when logged in as an admin' do
      before(:each) do
        @user = Fabricate(:admin)
        sign_in @user
      end

      it "should locate notice and redirect to problem" do
        problem = Fabricate(:problem, :app => app, :environment => "production")
        notice = Fabricate(:notice, :err => Fabricate(:err, :problem => problem))
        get :locate, :id => notice.id
        expect(response).to redirect_to(app_problem_path(problem.app, problem))
      end
    end
  end

end

