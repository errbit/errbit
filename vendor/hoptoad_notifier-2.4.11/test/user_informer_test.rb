require File.dirname(__FILE__) + '/helper'

class UserInformerTest < Test::Unit::TestCase
  should "modify output if there is a hoptoad id" do
    main_app = lambda do |env|
      env['hoptoad.error_id'] = 1
      [200, {}, ["<!-- HOPTOAD ERROR -->"]]
    end
    informer_app = HoptoadNotifier::UserInformer.new(main_app)

    ShamRack.mount(informer_app, "example.com")

    response = Net::HTTP.get_response(URI.parse("http://example.com/"))
    assert_equal "Hoptoad Error 1", response.body
    assert_equal 15, response["Content-Length"].to_i
  end

  should "not modify output if there is no hoptoad id" do
    main_app = lambda do |env|
      [200, {}, ["<!-- HOPTOAD ERROR -->"]]
    end
    informer_app = HoptoadNotifier::UserInformer.new(main_app)

    ShamRack.mount(informer_app, "example.com")

    response = Net::HTTP.get_response(URI.parse("http://example.com/"))
    assert_equal "<!-- HOPTOAD ERROR -->", response.body
  end
end
