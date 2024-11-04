require File.dirname(__FILE__) + '/helper'

class RecursionTest < Test::Unit::TestCase
  should "not allow infinite recursion" do
    hash = {:a => :a}
    hash[:hash] = hash
    notice = HoptoadNotifier::Notice.new(:parameters => hash)
    assert_equal "[possible infinite recursion halted]", notice.parameters[:hash]
  end
end
