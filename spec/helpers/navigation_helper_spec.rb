# frozen_string_literal: true

require "rails_helper"

RSpec.describe NavigationHelper, type: :helper do
  describe "#active_if_here" do
    before do
      allow(controller).to receive(:controller_name).and_return("users")
      allow(controller).to receive(:action_name).and_return("index")
    end

    context "with a single controller symbol" do
      it "returns ' active' when the current controller matches" do
        expect(helper.active_if_here(:users)).to eq(" active")
      end

      it "returns nil when the current controller does not match" do
        expect(helper.active_if_here(:blogs)).to be_nil
      end
    end

    context "with an array of controllers" do
      it "returns ' active' when the current controller is in the list" do
        expect(helper.active_if_here([:users, :blogs, :comments])).to eq(" active")
      end

      it "returns nil when the current controller is not in the list" do
        expect(helper.active_if_here([:blogs, :comments])).to be_nil
      end
    end

    context "with a hash of controllers to actions" do
      it "returns ' active' when the action is included for the matching controller" do
        expect(helper.active_if_here(users: :index)).to eq(" active")
      end

      it "returns ' active' when the action is in the list of actions for the controller" do
        expect(helper.active_if_here(users: [:index, :show])).to eq(" active")
      end

      it "returns ' active' when actions are specified as :all" do
        expect(helper.active_if_here(users: :all)).to eq(" active")
      end

      it "returns nil when the action is not included for the matching controller" do
        expect(helper.active_if_here(users: :create)).to be_nil
      end

      it "returns nil when the controller does not match any entry" do
        expect(helper.active_if_here(blogs: :index)).to be_nil
      end
    end
  end

  describe "#page_count_from_end" do
    it "returns the page number when counting from the last occurrence of a notice" do
      expect(page_count_from_end(1, 6)).to eq 6
      expect(page_count_from_end(6, 6)).to eq 1
      expect(page_count_from_end(2, 6)).to eq 5
    end

    it "properly handles strings for input" do
      expect(page_count_from_end("2", "6")).to eq 5
    end
  end
end
