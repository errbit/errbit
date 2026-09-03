# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  describe "#authenticated_locale" do
    it "returns a canonical locale for a noncanonical stored value" do
      user = build(:user)
      user[:locale] = "pt_br"
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)

      expect(controller.send(:authenticated_locale)).to eq("pt-BR")
    end
  end
end
