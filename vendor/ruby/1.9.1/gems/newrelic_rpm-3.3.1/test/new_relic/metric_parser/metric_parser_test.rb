require File.expand_path(File.join(File.dirname(__FILE__),'..', '..', 'test_helper'))
class NewRelic::MetricParser::MetricParserTest < Test::Unit::TestCase
  class ::AnApplicationClass
  end

  def test_metric_parser_does_not_instantiate_non_metric_parsing_classes
    assert NewRelic::MetricParser::MetricParser.for_metric_named('AnApplicationClass/Foo/Bar').
      is_a? NewRelic::MetricParser::MetricParser
  end

end
