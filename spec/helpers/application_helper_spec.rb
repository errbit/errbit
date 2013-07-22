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
  let(:notice) { Fabricate(:notice) }
  describe "#generate_problem_ical" do
    it 'return the ical format' do
      helper.generate_problem_ical([notice])
    end
  end
end
