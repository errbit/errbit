# frozen_string_literal: true

require "rails_helper"

RSpec.describe "users/index.html.erb", type: :view do
  let(:user) { create(:user) }

  before { assign(:users, Kaminari.paginate_array([user], total_count: 1).page(1)) }

  it "should see users option" do
    render

    expect(rendered).to match(/class="user_list"/)
  end
end
