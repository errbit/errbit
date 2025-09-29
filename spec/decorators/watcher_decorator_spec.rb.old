# frozen_string_literal: true

require "rails_helper"

RSpec.describe WatcherDecorator, type: :decorator do
  describe "#email_choosen" do
    context "with email define" do
      it "return blank" do
        expect(WatcherDecorator.new(double(email: "foo")).email_choosen).to eql ""
      end
    end

    context "without email define" do
      it "return choosen" do
        expect(WatcherDecorator.new(double(email: "")).email_choosen).to eql "chosen"
      end
    end
  end
end
