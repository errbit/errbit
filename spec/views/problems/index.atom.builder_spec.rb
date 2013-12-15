require 'spec_helper'

describe "problems/index.atom.builder" do

  it 'display problem message' do
    app = Fabricate :app
    view.stub(:problems).and_return([
      Fabricate(:problem, :message => 'foo', :app => app),
      Fabricate(:problem, :app => app)
    ])
    render
    expect(rendered).to match('foo')
  end

end
