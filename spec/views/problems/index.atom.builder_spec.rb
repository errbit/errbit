require 'spec_helper'

describe "problems/index.atom.builder" do

  it 'display problem message' do
    app = App.new(:new_record => false)
    assign(:problems, [Problem.new(
      :message => 'foo',
      :new_record => false, :app => app), Problem.new(:new_record => false, :app => app)])
    render
    rendered.should match('foo')
  end

end
