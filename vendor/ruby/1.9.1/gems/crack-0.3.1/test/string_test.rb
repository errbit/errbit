require 'test_helper'

class CrackTest < Test::Unit::TestCase
  context "snake_case" do
    should "lowercases one word CamelCase" do
      Crack::Util.snake_case("Merb").should == "merb"
    end

    should "makes one underscore snake_case two word CamelCase" do
      Crack::Util.snake_case("MerbCore").should == "merb_core"
    end

    should "handles CamelCase with more than 2 words" do
      Crack::Util.snake_case("SoYouWantContributeToMerbCore").should == "so_you_want_contribute_to_merb_core"
    end

    should "handles CamelCase with more than 2 capital letter in a row" do
      Crack::Util.snake_case("CNN").should == "cnn"
      Crack::Util.snake_case("CNNNews").should == "cnn_news"
      Crack::Util.snake_case("HeadlineCNNNews").should == "headline_cnn_news"
    end

    should "does NOT change one word lowercase" do
      Crack::Util.snake_case("merb").should == "merb"
    end

    should "leaves snake_case as is" do
      Crack::Util.snake_case("merb_core").should == "merb_core"
    end
  end
end