require 'spec_helper'

describe NoticesController do
  
  context 'POST[XML] notices#create' do
    before do
      @xml = Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read
      @app = Factory(:app_with_watcher)
      App.stub(:find_by_api_key!).and_return(@app)
      @notice = Notice.from_xml(@xml)
      
      request.env['Content-type'] = 'text/xml'
      request.env['Accept'] = 'text/xml, application/xml'
      request.should_receive(:raw_post).and_return(@xml)
    end
    
    it "generates a notice from the xml" do
      Notice.should_receive(:from_xml).with(@xml).and_return(@notice)
      post :create
    end
    
    it "sends a notification email" do
      post :create
      email = ActionMailer::Base.deliveries.last
      email.to.should include(@app.watchers.first.email)
      email.subject.should include(@notice.err.message)
    end
  end
  
end
