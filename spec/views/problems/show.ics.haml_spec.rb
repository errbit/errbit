require 'spec_helper'

describe "problems/show.html.ics" do
  let(:problem) { Fabricate(:problem) }
  before do
    view.stub(:problem).and_return(problem)
  end

  it 'should work' do
    render :template => 'problems/show', :formats => [:ics], :handlers => [:haml]
  end


end
