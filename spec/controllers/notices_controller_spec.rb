require 'spec_helper'

describe NoticesController do
  
  context 'notices API' do
    before do
      @xml = Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read
      @app = Factory(:app_with_watcher)
      App.stub(:find_by_api_key!).and_return(@app)
      @notice = Notice.from_xml(@xml)
      
      request.env['Content-type'] = 'text/xml'
      request.env['Accept'] = 'text/xml, application/xml'
    end
    
    it "generates a notice from xml [POST]" do
      Notice.should_receive(:from_xml).with(@xml).and_return(@notice)
      request.should_receive(:raw_post).and_return(@xml)
      post :create
    end
    
    it "generates a notice from xml [GET]" do
      Notice.should_receive(:from_xml).with(@xml).and_return(@notice)
      get :create, {:data => @xml}
    end
    
    it "sends a notification email" do
      request.should_receive(:raw_post).and_return(@xml)
      post :create
      email = ActionMailer::Base.deliveries.last
      email.to.should include(@app.watchers.first.email)
      email.subject.should include(@notice.err.message)
      email.subject.should include("[#{@app.name}]")
      email.subject.should include("[#{@notice.err.environment}]")
    end
  end
  
end
