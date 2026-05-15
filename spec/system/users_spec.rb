# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :system do
  describe "#index" do
    current_user = create(:user, name: "Ihor Zubkov")

    sign_in(current_user)

    visit users_path


  end
end
