require 'spec_helper'

describe NoticesController do
  
  context 'POST[XML] notices#create' do
    before do
      @xml = Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read
      @notice = Notice.from_xml(@xml)
      
      request.env['Content-type'] = 'text/xml'
      request.env['Accept'] = 'text/xml, application/xml'
      request.should_receive(:raw_post).and_return(@xml)
    end
    
    it "generates a notice from the xml" do
      Notice.should_receive(:from_xml).with(@xml).and_return(@notice)
      post :create
    end
  end
  
end
