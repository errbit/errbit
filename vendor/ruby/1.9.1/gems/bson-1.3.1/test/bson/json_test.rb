require './test/test_helper'
require 'rubygems'
require 'json'

class JSONTest < Test::Unit::TestCase

  # This test passes when run by itself but fails
  # when run as part of the whole test suite.
  def test_object_id_as_json
    warn "Pending test object id as json"
    #id = BSON::ObjectId.new

    #obj = {'_id' => id}
    #assert_equal "{\"_id\":#{id.to_json}}", obj.to_json
  end

end
