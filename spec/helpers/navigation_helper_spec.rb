require 'spec_helper'

describe NavigationHelper do
  describe '#page_count_from_end' do
    it 'returns the page number when counting from the last occurrence of a notice' do
      page_count_from_end(1, 6).should == 6
      page_count_from_end(6, 6).should == 1
      page_count_from_end(2, 6).should == 5
    end

    it 'properly handles strings for input' do
      page_count_from_end('2', '6').should == 5
    end
  end
end
