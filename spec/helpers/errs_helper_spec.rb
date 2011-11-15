require 'spec_helper'

describe ErrsHelper do
  describe '#truncated_err_message' do
    it 'is html safe' do
      problem = double('problem', :message => '#<NoMethodError: ...>')
      truncated = helper.truncated_err_message(problem)
      truncated.should be_html_safe
      truncated.should_not include('<', '>')
    end
  end
end
