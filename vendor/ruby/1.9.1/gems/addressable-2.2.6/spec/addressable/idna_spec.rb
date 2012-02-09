# coding: utf-8
# Copyright (C) 2006-2011 Bob Aman
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.


# Have to use RubyGems to load the idn gem.
require "rubygems"

require "addressable/idna"

shared_examples_for "converting from unicode to ASCII" do
  it "should convert 'www.google.com' correctly" do
    Addressable::IDNA.to_ascii("www.google.com").should == "www.google.com"
  end

  it "should convert 'www.詹姆斯.com' correctly" do
    Addressable::IDNA.to_ascii(
      "www.詹姆斯.com"
    ).should == "www.xn--8ws00zhy3a.com"
  end

  it "should convert 'www.Iñtërnâtiônàlizætiøn.com' correctly" do
    "www.Iñtërnâtiônàlizætiøn.com"
    Addressable::IDNA.to_ascii(
      "www.I\xC3\xB1t\xC3\xABrn\xC3\xA2ti\xC3\xB4" +
      "n\xC3\xA0liz\xC3\xA6ti\xC3\xB8n.com"
    ).should == "www.xn--itrntinliztin-vdb0a5exd8ewcye.com"
  end

  it "should convert 'www.Iñtërnâtiônàlizætiøn.com' correctly" do
    Addressable::IDNA.to_ascii(
      "www.In\xCC\x83te\xCC\x88rna\xCC\x82tio\xCC\x82n" +
      "a\xCC\x80liz\xC3\xA6ti\xC3\xB8n.com"
    ).should == "www.xn--itrntinliztin-vdb0a5exd8ewcye.com"
  end

  it "should convert " +
      "'www.ほんとうにながいわけのわからないどめいんめいのらべるまだながくしないとたりない.w3.mag.keio.ac.jp' " +
      "correctly" do
    Addressable::IDNA.to_ascii(
      "www.\343\201\273\343\202\223\343\201\250\343\201\206\343\201\253\343" +
      "\201\252\343\201\214\343\201\204\343\202\217\343\201\221\343\201\256" +
      "\343\202\217\343\201\213\343\202\211\343\201\252\343\201\204\343\201" +
      "\251\343\202\201\343\201\204\343\202\223\343\202\201\343\201\204\343" +
      "\201\256\343\202\211\343\201\271\343\202\213\343\201\276\343\201\240" +
      "\343\201\252\343\201\214\343\201\217\343\201\227\343\201\252\343\201" +
      "\204\343\201\250\343\201\237\343\202\212\343\201\252\343\201\204." +
      "w3.mag.keio.ac.jp"
    ).should ==
      "www.xn--n8jaaaaai5bhf7as8fsfk3jnknefdde3" +
      "fg11amb5gzdb4wi9bya3kc6lra.w3.mag.keio.ac.jp"
  end

  it "should convert " +
      "'www.ほんとうにながいわけのわからないどめいんめいのらべるまだながくしないとたりない.w3.mag.keio.ac.jp' " +
      "correctly" do
    Addressable::IDNA.to_ascii(
      "www.\343\201\273\343\202\223\343\201\250\343\201\206\343\201\253\343" +
      "\201\252\343\201\213\343\202\231\343\201\204\343\202\217\343\201\221" +
      "\343\201\256\343\202\217\343\201\213\343\202\211\343\201\252\343\201" +
      "\204\343\201\250\343\202\231\343\202\201\343\201\204\343\202\223\343" +
      "\202\201\343\201\204\343\201\256\343\202\211\343\201\270\343\202\231" +
      "\343\202\213\343\201\276\343\201\237\343\202\231\343\201\252\343\201" +
      "\213\343\202\231\343\201\217\343\201\227\343\201\252\343\201\204\343" +
      "\201\250\343\201\237\343\202\212\343\201\252\343\201\204." +
      "w3.mag.keio.ac.jp"
    ).should ==
      "www.xn--n8jaaaaai5bhf7as8fsfk3jnknefdde3" +
      "fg11amb5gzdb4wi9bya3kc6lra.w3.mag.keio.ac.jp"
  end

  it "should convert '点心和烤鸭.w3.mag.keio.ac.jp' correctly" do
    Addressable::IDNA.to_ascii(
      "点心和烤鸭.w3.mag.keio.ac.jp"
    ).should == "xn--0trv4xfvn8el34t.w3.mag.keio.ac.jp"
  end

  it "should convert '가각갂갃간갅갆갇갈갉힢힣.com' correctly" do
    Addressable::IDNA.to_ascii(
      "가각갂갃간갅갆갇갈갉힢힣.com"
    ).should == "xn--o39acdefghijk5883jma.com"
  end

  it "should convert " +
      "'\347\242\274\346\250\231\346\272\226\350" +
      "\220\254\345\234\213\347\242\274.com' correctly" do
    Addressable::IDNA.to_ascii(
      "\347\242\274\346\250\231\346\272\226\350" +
      "\220\254\345\234\213\347\242\274.com"
    ).should == "xn--9cs565brid46mda086o.com"
  end

  it "should convert 'ﾘ宠퐱〹.com' correctly" do
    Addressable::IDNA.to_ascii(
      "\357\276\230\345\256\240\355\220\261\343\200\271.com"
    ).should == "xn--eek174hoxfpr4k.com"
  end

  it "should convert 'リ宠퐱卄.com' correctly" do
    Addressable::IDNA.to_ascii(
      "\343\203\252\345\256\240\355\220\261\345\215\204.com"
    ).should == "xn--eek174hoxfpr4k.com"
  end

  it "should convert 'ᆵ' correctly" do
    Addressable::IDNA.to_ascii(
      "\341\206\265"
    ).should == "xn--4ud"
  end

  it "should convert 'ﾯ' correctly" do
    Addressable::IDNA.to_ascii(
      "\357\276\257"
    ).should == "xn--4ud"
  end
end

shared_examples_for "converting from ASCII to unicode" do
  it "should convert 'www.google.com' correctly" do
    Addressable::IDNA.to_unicode("www.google.com").should == "www.google.com"
  end

  it "should convert 'www.詹姆斯.com' correctly" do
    Addressable::IDNA.to_unicode(
      "www.xn--8ws00zhy3a.com"
    ).should == "www.詹姆斯.com"
  end

  it "should convert 'www.iñtërnâtiônàlizætiøn.com' correctly" do
    Addressable::IDNA.to_unicode(
      "www.xn--itrntinliztin-vdb0a5exd8ewcye.com"
    ).should == "www.iñtërnâtiônàlizætiøn.com"
  end

  it "should convert " +
      "'www.ほんとうにながいわけのわからないどめいんめいのらべるまだながくしないとたりない.w3.mag.keio.ac.jp' " +
      "correctly" do
    Addressable::IDNA.to_unicode(
      "www.xn--n8jaaaaai5bhf7as8fsfk3jnknefdde3" +
      "fg11amb5gzdb4wi9bya3kc6lra.w3.mag.keio.ac.jp"
    ).should ==
      "www.ほんとうにながいわけのわからないどめいんめいのらべるまだながくしないとたりない.w3.mag.keio.ac.jp"
  end

  it "should convert '点心和烤鸭.w3.mag.keio.ac.jp' correctly" do
    Addressable::IDNA.to_unicode(
      "xn--0trv4xfvn8el34t.w3.mag.keio.ac.jp"
    ).should == "点心和烤鸭.w3.mag.keio.ac.jp"
  end

  it "should convert '가각갂갃간갅갆갇갈갉힢힣.com' correctly" do
    Addressable::IDNA.to_unicode(
      "xn--o39acdefghijk5883jma.com"
    ).should == "가각갂갃간갅갆갇갈갉힢힣.com"
  end

  it "should convert " +
      "'\347\242\274\346\250\231\346\272\226\350" +
      "\220\254\345\234\213\347\242\274.com' correctly" do
    Addressable::IDNA.to_unicode(
      "xn--9cs565brid46mda086o.com"
    ).should ==
      "\347\242\274\346\250\231\346\272\226\350" +
      "\220\254\345\234\213\347\242\274.com"
  end

  it "should convert 'リ宠퐱卄.com' correctly" do
    Addressable::IDNA.to_unicode(
      "xn--eek174hoxfpr4k.com"
    ).should == "\343\203\252\345\256\240\355\220\261\345\215\204.com"
  end

  it "should convert 'ﾯ' correctly" do
    Addressable::IDNA.to_unicode(
      "xn--4ud"
    ).should == "\341\206\265"
  end
end

describe Addressable::IDNA, "when using the pure-Ruby implementation" do
  before do
    Addressable.send(:remove_const, :IDNA)
    load "addressable/idna/pure.rb"
  end

  it_should_behave_like "converting from unicode to ASCII"
  it_should_behave_like "converting from ASCII to unicode"
end

begin
  require "idn"

  describe Addressable::IDNA, "when using the native-code implementation" do
    before do
      Addressable.send(:remove_const, :IDNA)
      load "addressable/idna/native.rb"
    end

    it_should_behave_like "converting from unicode to ASCII"
    it_should_behave_like "converting from ASCII to unicode"
  end
rescue LoadError
  # Cannot test the native implementation without libidn support.
  warn('Could not load native IDN implementation.')
end
