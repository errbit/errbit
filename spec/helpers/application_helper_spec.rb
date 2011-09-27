require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the AbcHelper. For example:
#
# describe AbcHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       helper.concat_strings("this","that").should == "this that"
#     end
#   end
# end
describe ApplicationHelper do
  describe "get_host" do
    it "returns host if url is valid" do
      helper.get_host("http://example.com/resource/12").should == 'example.com'
    end
    
    it "returns 'N/A' when url is not valid" do
      helper.get_host("some string").should == 'N/A'
    end

    it "returns 'N/A' when url is empty" do
      helper.get_host({}).should == 'N/A'
    end
  end
end
