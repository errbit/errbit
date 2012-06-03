require 'spec_helper'

describe "apps/index.html.haml" do
  before do
    app = Fabricate(:app, :deploys => [Fabricate(:deploy, :revision => "123456789abcdef")])
    assign :apps, [app]
    assign :problem_counts, {app.id => 0}
    assign :unresolved_counts, {app.id => 0}
    controller.stub(:current_user) { Fabricate(:user) }
  end

  describe "deploy column" do
    it "should show the first 7 characters of the revision in parentheses" do
      render
      rendered.should match(/\(1234567\)/)
    end
  end
end

