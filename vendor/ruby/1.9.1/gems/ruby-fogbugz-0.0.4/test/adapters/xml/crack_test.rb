require 'test_helper'
require 'ruby_fogbugz/adapters/xml/cracker'

class Cracker < FogTest
  test 'should parse XML and get rid of the response namespace' do
    XML = <<-xml
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
        <version>2</version>
      </response>
    xml

    assert_equal({"version" => "2"}, Fogbugz::Adapter::XML::Cracker.parse(XML))
  end
end
