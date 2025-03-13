describe Sparklines do
  it "includes each percentage and adds a percent sign" do
    percentages = [33, 75, 100]
    sparklines_html = Sparklines.for_relative_percentages(percentages)
    percentages.each do |percentage|
      expect(sparklines_html).to include("#{percentage}%")
    end
  end

  it "has the right number of i tags" do
    percentages = [75, 100]
    sparklines_html = Sparklines.for_relative_percentages(percentages)
    number_of_i_tags = sparklines_html.scan(/<i/).size
    expect(number_of_i_tags).to eq(2)
  end
end
