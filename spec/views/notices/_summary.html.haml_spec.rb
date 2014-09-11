require 'spec_helper'

describe "notices/_summary.html.haml" do
  let(:notice) { Fabricate(:notice, :framework => 'Rails 3.2.11') }

  it "renders application framework" do
    render "notices/summary", :notice => notice, :problem => notice.problem

    expect(rendered).to have_content('Rails 3.2.11')
  end
end

