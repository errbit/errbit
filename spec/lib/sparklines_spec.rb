# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sparklines do
  it "includes each percentage and adds a percent sign" do
    percentages = [33, 75, 100]
    html = described_class.for_relative_percentages(percentages)
    percentages.each do |percentage|
      expect(html).to include("#{percentage}%")
    end
  end

  it "has the right number of i tags" do
    percentages = [75, 100]
    html = described_class.for_relative_percentages(percentages)
    document = Nokogiri::HTML.fragment(html)
    number_of_i_tags = document.css("i").count
    expect(number_of_i_tags).to eq(2)
  end
end
