# frozen_string_literal: true

require "rails_helper"

RSpec.describe "problems/show.ics.erb", type: :view do
  let(:problem) { Fabricate(:problem) }

  before do
    allow(view).to receive(:problem).and_return(problem)
  end

  it "works" do
    render template: "problems/show", formats: [:ics]
  end
end
