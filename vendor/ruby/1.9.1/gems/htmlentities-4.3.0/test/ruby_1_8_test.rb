# encoding: UTF-8
require File.expand_path("../common", __FILE__)

unless ENCODING_AWARE_RUBY
  class HTMLEntities::Ruby18Test < Test::Unit::TestCase

    # Reported by Benoit Larroque
    def test_should_encode_without_error_when_KCODE_is_not_UTF_8
      kcode = $KCODE
      $KCODE = "n"
      coder = HTMLEntities.new
      text = [8212].pack('U')
      assert_equal "&#8212;", coder.encode(text, :decimal)
      $KCODE = kcode
    end

  end
end
