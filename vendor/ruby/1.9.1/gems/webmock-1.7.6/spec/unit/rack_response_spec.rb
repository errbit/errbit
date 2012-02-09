require 'spec_helper'

describe WebMock::RackResponse do
  before :each do
    @rack_response = WebMock::RackResponse.new(MyRackApp)
  end

  it "should hook up to a rack appliance" do
    request = WebMock::RequestSignature.new(:get, 'www.example.com')
    response = @rack_response.evaluate(request)

    response.status.first.should == 200
    response.body.should include('This is my root!')
  end

  it "should send along params" do
    request = WebMock::RequestSignature.new(:get, 'www.example.com/greet?name=Johnny')

    response = @rack_response.evaluate(request)

    response.status.first.should == 200
    response.body.should include('Hello, Johnny')
  end

  it "should send along POST params" do
    request = WebMock::RequestSignature.new(:post, 'www.example.com/greet',
      :body => 'name=Jimmy'
    )

    response = @rack_response.evaluate(request)
    response.body.should include('Good to meet you, Jimmy!')
  end
end
