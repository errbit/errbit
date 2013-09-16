require 'spec_helper'

describe "apps/show.atom.builder" do
  let(:app) { stub_model(App) }
  let(:problems) { [
    stub_model(Problem, :message => 'foo', :app => app)
  ]}

  before do
    view.stub(:app).and_return(app)
    view.stub(:problems).and_return(problems)
  end

  context "with errs" do
    it 'see the errs message' do
      render
      expect(rendered).to match(problems.first.message)
    end
  end

end
