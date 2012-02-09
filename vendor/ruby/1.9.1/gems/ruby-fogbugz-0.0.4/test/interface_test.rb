require 'test_helper.rb'

class FogTest
  CREDENTIALS = {
    :email    => "test@test.com",
    :password => 'seekrit',
    :uri      => 'http://fogbugz.test.com'
  }
end

class BasicInterface < FogTest
  def setup
    Fogbugz.adapter[:http] = mock()
    Fogbugz.adapter[:http].expects(:new)

    Fogbugz.adapter[:xml] = mock()

    @fogbugz = Fogbugz::Interface.new(CREDENTIALS)
  end

  test 'when instantiating options should be overwriting and be publicly available' do
    assert_equal CREDENTIALS, @fogbugz.options
  end
end

class InterfaceRequests < FogTest
  def setup
    Fogbugz.adapter[:http].expects(:new)
  end

  test 'authentication should send correct parameters' do

    fogbugz = Fogbugz::Interface.new(CREDENTIALS)
    fogbugz.http.expects(:request).with(:logon, 
                                        :params => {
                                          :email => CREDENTIALS[:email],
                                          :password => CREDENTIALS[:password]
                                        }).returns("token")

    fogbugz.xml.expects(:parse).with("token").returns({"token" => "22"})

    fogbugz.authenticate
  end

  test 'requesting with an action should send along token and correct parameters' do
    fogbugz = Fogbugz::Interface.new(CREDENTIALS)
    fogbugz.token = 'token'
    fogbugz.http.expects(:request).with(:search, {:params => {:q => 'case', :token => 'token'}}).returns("omgxml")
    fogbugz.xml.expects(:parse).with("omgxml")
    fogbugz.command(:search, :q => 'case')
  end

  test 'throws an exception if #command is requested with no token' do
    fogbugz = Fogbugz::Interface.new(CREDENTIALS)
    fogbugz.token = nil

    assert_raises Fogbugz::Interface::RequestError do
      fogbugz.command(:search, :q => 'case')
    end
  end
end
