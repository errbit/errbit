require 'spec_helper'

describe "problems/index.atom.builder" do

  it 'display problem message' do
    app = Fabricate :app
    view.stub(:problems).and_return([
      Fabricate(:err, problem: Fabricate(:problem, message: 'foo', app: app)).problem,
      Fabricate(:err, problem: Fabricate(:problem, app: app)).problem
    ])
    render
    expect(rendered).to match('foo')
  end

end
