# frozen_string_literal: true

require "rails_helper"

RSpec.describe "problems/show.ics.erb", type: :view do
  let(:problem) { ProblemDecorator.new(create(:problem)) }

  before do
    assign(:problem, problem)
  end

  it "works" do
    render template: "problems/show", formats: [:ics]
  end
end
