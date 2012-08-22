require 'spec_helper'

describe "apps/index.html.haml" do
  before do
    app = stub_model(App, :deploys => [stub_model(Deploy, :created_at => Time.now, :revision => "123456789abcdef")])
    assign :apps, [app]
    assign :problem_counts, {app.id => 0}
    assign :unresolved_counts, {app.id => 0}
    controller.stub(:current_user) { stub_model(User) }
  end

  describe "deploy column" do
    it "should show the first 7 characters of the revision in parentheses" do
      render
      rendered.should match(/\(1234567\)/)
    end
  end
end

