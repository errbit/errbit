# frozen_string_literal: true

require "rails_helper"

RSpec.describe "problems/index.atom.builder", type: :view do
  it "display problem message" do
    app = App.new(new_record: false)
    allow(view).to receive(:problems).and_return([Problem.new(
      message: "foo",
      new_record: false, app: app
    ), Problem.new(new_record: false, app: app)])
    render
    expect(rendered).to match("foo")
  end
end
