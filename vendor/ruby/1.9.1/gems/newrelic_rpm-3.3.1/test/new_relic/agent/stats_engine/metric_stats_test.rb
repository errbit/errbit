require File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','test_helper'))


class NewRelic::Agent::MetricStatsTest < Test::Unit::TestCase
  def setup
    NewRelic::Agent.manual_start
    @engine = NewRelic::Agent.instance.stats_engine
  rescue => e
    puts e
    puts e.backtrace.join("\n")
  end
  
  def teardown
    @engine.harvest_timeslice_data({},{})
    super
  end

  def test_get_no_scope
    s1 = @engine.get_stats "a"
    s2 = @engine.get_stats "a"
    s3 = @engine.get_stats "b"

    assert_not_nil s1
    assert_not_nil s2
    assert_not_nil s3

    assert s1 == s2
    assert s1 != s3
  end

  def test_harvest
    @engine.clear_stats
    s1 = @engine.get_stats "a"
    s2 = @engine.get_stats "c"

    s1.trace_call 10
    s2.trace_call 1
    s2.trace_call 3

    assert_equal 1, @engine.get_stats("a").call_count
    assert_equal 10, @engine.get_stats("a").total_call_time

    assert_equal 2, @engine.get_stats("c").call_count
    assert_equal 4, @engine.get_stats("c").total_call_time

    metric_data = @engine.harvest_timeslice_data({}, {}).values
    
    # after harvest, all the metrics should be reset
    assert_equal 0, @engine.get_stats("a").call_count
    assert_equal 0, @engine.get_stats("a").total_call_time

    assert_equal 0, @engine.get_stats("c").call_count
    assert_equal 0, @engine.get_stats("c").total_call_time

    metric_data = metric_data.reverse if metric_data[0].metric_spec.name != "a"

    assert_equal 'a', metric_data[0].metric_spec.name

    assert_equal 1, metric_data[0].stats.call_count
    assert_equal 10, metric_data[0].stats.total_call_time
  end

  def test_harvest_with_merge
    s = @engine.get_stats "a"
    s.trace_call 1

    assert_equal 1, @engine.get_stats("a").call_count

    harvest = @engine.harvest_timeslice_data({}, {})
    assert_equal 0, s.call_count
    s.trace_call 2
    assert_equal 1, s.call_count

    # this calk should merge the contents of the previous harvest,
    # so the stats for metric "a" should have 2 data points
    harvest = @engine.harvest_timeslice_data(harvest, {})
    stats = harvest.fetch(NewRelic::MetricSpec.new("a")).stats
    assert_equal 2, stats.call_count
    assert_equal 3, stats.total_call_time
  end
end

