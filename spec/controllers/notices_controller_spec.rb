require 'spec_helper'

describe NoticesController do
  it_requires_authentication :for => { :locate => :get }

  let(:app) { Fabricate(:app) }

  context 'notices API' do
    before do
      @xml = Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read
      @app = Fabricate(:app_with_watcher)
      App.stub(:find_by_api_key!).and_return(@app)
      @notice = App.report_error!(@xml)
    end

    it "generates a notice from raw xml [POST]" do
      App.should_receive(:report_error!).with(@xml).and_return(@notice)
      request.should_receive(:raw_post).and_return(@xml)
      post :create, :format => :xml
      response.should be_success
      # Same RegExp from Airbrake::Sender#send_to_airbrake (https://github.com/airbrake/airbrake/blob/master/lib/airbrake/sender.rb#L53)
      # Inspired by https://github.com/airbrake/airbrake/blob/master/test/sender_test.rb
      response.body.should match(%r{<id[^>]*>#{@notice.id}</id>})
      response.body.should match(%r{<url[^>]*>(.+)#{locate_path(@notice.id)}</url>})
    end

    it "generates a notice from xml in a data param [POST]" do
      App.should_receive(:report_error!).with(@xml).and_return(@notice)
      post :create, :data => @xml, :format => :xml
      response.should be_success
      # Same RegExp from Airbrake::Sender#send_to_airbrake (https://github.com/airbrake/airbrake/blob/master/lib/airbrake/sender.rb#L53)
      # Inspired by https://github.com/airbrake/airbrake/blob/master/test/sender_test.rb
      response.body.should match(%r{<id[^>]*>#{@notice.id}</id>})
      response.body.should match(%r{<url[^>]*>(.+)#{locate_path(@notice.id)}</url>})
    end

    it "generates a notice from xml [GET]" do
      App.should_receive(:report_error!).with(@xml).and_return(@notice)
      get :create, :data => @xml, :format => :xml
      response.should be_success
      response.body.should match(%r{<id[^>]*>#{@notice.id}</id>})
      response.body.should match(%r{<url[^>]*>(.+)#{locate_path(@notice.id)}</url>})
    end

    it "sends a notification email" do
      App.should_receive(:report_error!).with(@xml).and_return(@notice)
      request.should_receive(:raw_post).and_return(@xml)
      post :create, :format => :xml
      response.should be_success
      response.body.should match(%r{<id[^>]*>#{@notice.id}</id>})
      response.body.should match(%r{<url[^>]*>(.+)#{locate_path(@notice.id)}</url>})
      email = ActionMailer::Base.deliveries.last
      email.to.should include(@app.watchers.first.email)
      email.subject.should include(@notice.message.truncate(50))
      email.subject.should include("[#{@app.name}]")
      email.subject.should include("[#{@notice.environment_name}]")
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
        response.should redirect_to(app_problem_path(problem.app, problem))
      end
    end
  end

end

