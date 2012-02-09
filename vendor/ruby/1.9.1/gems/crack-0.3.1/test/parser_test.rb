require 'test_helper'

class ParserTest < Test::Unit::TestCase
  should "default to REXMLParser" do
    Crack::XML.parser.should == Crack::REXMLParser
  end

  context "with a custom Parser" do
	  class CustomParser
			def self.parse(xml)
				xml
			end
		end

    setup do
      Crack::XML.parser = CustomParser
    end

    should "use the custom Parser" do
			Crack::XML.parse("<xml/>").should == "<xml/>"
    end

    teardown do
      Crack::XML.parser = nil
    end
  end
end
