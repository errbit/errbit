#- ©2009 Rick DeNatale, All rights reserved. Refer to the file README.txt for the license

require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe RiCal::PropertyValue::Text do

  context ".ruby_value" do

    it "should handle escapes according to RFC2445 Sec 4.3.11 p 45" do
      expected = "this\\ has\, \nescaped\;\n\\x characters"
      it = RiCal::PropertyValue::Text.new(nil, :value => 'this\\ has\, \nescaped\;\N\x characters')
      it.ruby_value.should == expected
    end
  end

  context ".convert" do

    it "should handle escapes according to RFC2445 Sec 4.3.11 p 45" do
      expected = ':this has\, \nescaped\;\n characters\ncr\nnlcr\ncrnl'
      it = RiCal::PropertyValue::Text.convert(nil, "this\ has, \nescaped;\n characters\rcr\n\rnlcr\r\ncrnl")
      it.to_s.should == expected
    end
  end

end