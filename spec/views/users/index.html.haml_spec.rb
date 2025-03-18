# frozen_string_literal: true

require "rails_helper"

RSpec.describe "users/index.html.haml", type: :view do
  let(:user) { stub_model(User) }
  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:users).and_return(
      Kaminari.paginate_array([user], total_count: 1).page(1)
    )
  end
  it "should see users option" do
    render
    expect(rendered).to match(/class='user_list'/)
  end
end
