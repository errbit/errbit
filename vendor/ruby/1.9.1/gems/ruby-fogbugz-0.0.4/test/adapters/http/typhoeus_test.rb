require 'test_helper'
require 'ruby_fogbugz/adapters/http/typhoeus'

class Typhoeuser < FogTest
  test '#request should order the params right' do
    response = mock()
    response.expects(:body)

    t = Fogbugz::Adapter::HTTP::Typhoeuser.new(:uri => 'http://test.com')
    t.requester.expects(:get).returns(response)
    t.request(:action, :params => {:one => "two", :three => "four"})
  end
end
