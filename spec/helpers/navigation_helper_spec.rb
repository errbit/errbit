require 'spec_helper'

describe NavigationHelper do
  describe '#page_count_from_end' do
    it 'returns the page number when counting from the last occurrence of a notice' do
      expect(page_count_from_end(1, 6)).to eq 6
      expect(page_count_from_end(6, 6)).to eq 1
      expect(page_count_from_end(2, 6)).to eq 5
    end

    it 'properly handles strings for input' do
      expect(page_count_from_end('2', '6')).to eq 5
    end
  end
end
