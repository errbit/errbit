# frozen_string_literal: true

require "rails_helper"

RSpec.describe "users/edit.html.erb", type: :view do
  let(:user) { stub_model(Errbit::User, name: "shingara") }

  before do
    allow(view).to receive(:current_user).and_return(user)

    assign(:user, user)
  end

  it "is expected to have per_page option" do
    render

    expect(rendered).to match(/id="errbit_user_per_page"/)
  end

  it "is expected to have time_zone option" do
    render

    expect(rendered).to match(/id="errbit_user_time_zone"/)
  end
end
