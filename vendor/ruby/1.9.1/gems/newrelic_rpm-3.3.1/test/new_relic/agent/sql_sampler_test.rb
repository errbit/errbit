require File.expand_path(File.join(File.dirname(__FILE__),'..','..','test_helper'))

class NewRelic::Agent::SqlSamplerTest < Test::Unit::TestCase
  
  def setup
    agent = NewRelic::Agent.instance
    stats_engine = NewRelic::Agent::StatsEngine.new
    agent.stubs(:stats_engine).returns(stats_engine)
    @sampler = NewRelic::Agent::SqlSampler.new
    @connection = stub('ActiveRecord connection', :execute => 'result')
    NewRelic::Agent::Database.stubs(:get_connection).returns(@connection)
  end
  
  def test_notice_first_scope_push
    assert_nil @sampler.transaction_data    
    @sampler.notice_first_scope_push nil
    assert_not_nil @sampler.transaction_data
    @sampler.notice_scope_empty
    assert_nil @sampler.transaction_data
  end
  
  def test_notice_sql_no_transaction
    assert_nil @sampler.transaction_data    
    @sampler.notice_sql "select * from test", "Database/test/select", nil, 10
  end

  def test_notice_sql
    @sampler.notice_first_scope_push nil
    @sampler.notice_sql "select * from test", "Database/test/select", nil, 1.5
    @sampler.notice_sql "select * from test2", "Database/test2/select", nil, 1.3
    # this sql will not be captured
    @sampler.notice_sql "select * from test", "Database/test/select", nil, 0
    assert_not_nil @sampler.transaction_data
    assert_equal 2, @sampler.transaction_data.sql_data.size
  end
  
  def test_harvest_slow_sql
    data = NewRelic::Agent::TransactionSqlData.new
    data.set_transaction_info("WebTransaction/Controller/c/a", "/c/a", {},
                              'guid')
    data.sql_data.concat [
      NewRelic::Agent::SlowSql.new("select * from test", "Database/test/select", {}, 1.5), 
      NewRelic::Agent::SlowSql.new("select * from test", "Database/test/select", {}, 1.2), 
      NewRelic::Agent::SlowSql.new("select * from test2", "Database/test2/select", {}, 1.1)
    ]
    @sampler.harvest_slow_sql data
      
    assert_equal 2, @sampler.sql_traces.size
  end
  
  def test_sql_aggregation
    sql_trace = NewRelic::Agent::SqlTrace.new("select * from test", 
            NewRelic::Agent::SlowSql.new("select * from test",
                "Database/test/select", {}, 1.2),
        "tx_name", "uri")
      
    sql_trace.aggregate NewRelic::Agent::SlowSql.new("select * from test", "Database/test/select", {}, 1.5), "slowest_tx_name", "slow_uri"
    sql_trace.aggregate NewRelic::Agent::SlowSql.new("select * from test", "Database/test/select", {}, 1.1), "other_tx_name", "uri2"
    
    assert_equal 3, sql_trace.call_count
    assert_equal "slowest_tx_name", sql_trace.path
    assert_equal "slow_uri", sql_trace.url
    assert_equal 1.5, sql_trace.max_call_time
  end
  
  def test_harvest
    data = NewRelic::Agent::TransactionSqlData.new
    data.set_transaction_info("WebTransaction/Controller/c/a", "/c/a", {},
                              'guid')
    data.sql_data.concat [NewRelic::Agent::SlowSql.new("select * from test", "Database/test/select", {}, 1.5), 
                          NewRelic::Agent::SlowSql.new("select * from test", "Database/test/select", {}, 1.2), 
                          NewRelic::Agent::SlowSql.new("select * from test2", "Database/test2/select", {}, 1.1)]
    @sampler.harvest_slow_sql data
      
    sql_traces = @sampler.harvest
    assert_equal 2, sql_traces.size
  end

  def test_harvest_should_not_take_more_than_10
    data = NewRelic::Agent::TransactionSqlData.new
    data.set_transaction_info("WebTransaction/Controller/c/a", "/c/a", {}, 'guid')
    15.times do |i|
      data.sql_data << NewRelic::Agent::SlowSql.new("select * from test#{(i+97).chr}",
                                                    "Database/test#{(i+97).chr}/select", {}, i)
    end
    
    @sampler.harvest_slow_sql data
    result = @sampler.harvest
    
    assert_equal(10, result.size)
    assert_equal(14, result.sort{|a,b| b.max_call_time <=> a.max_call_time}.first.total_call_time)
  end

  def test_harvest_should_aggregate_similar_queries
    data = NewRelic::Agent::TransactionSqlData.new
    data.set_transaction_info("WebTransaction/Controller/c/a", "/c/a", {},
                              'guid')
    queries = [
               NewRelic::Agent::SlowSql.new("select  * from test where foo in (1, 2)  ", "Database/test/select", {}, 1.5), 
               NewRelic::Agent::SlowSql.new("select * from test where foo in (1,2, 3 ,4,  5,6, 'snausage')", "Database/test/select", {}, 1.2), 
               NewRelic::Agent::SlowSql.new("select * from test2 where foo in (1,2)", "Database/test2/select", {}, 1.1)
              ]
    data.sql_data.concat(queries)
    @sampler.harvest_slow_sql data
      
    sql_traces = @sampler.harvest
    assert_equal 2, sql_traces.size
  end

  def test_harvest_should_collect_explain_plans
    @connection.expects(:execute).with("EXPLAIN select * from test") \
     .returns([{"header0" => 'foo0', "header1" => 'foo1', "header2" => 'foo2'}])
    @connection.expects(:execute).with("EXPLAIN select * from test2") \
     .returns([{"header0" => 'bar0', "header1" => 'bar1', "header2" => 'bar2'}])

    data = NewRelic::Agent::TransactionSqlData.new
    data.set_transaction_info("WebTransaction/Controller/c/a", "/c/a", {},
                              'guid')
    queries = [
               NewRelic::Agent::SlowSql.new("select * from test", "Database/test/select", {}, 1.5), 
               NewRelic::Agent::SlowSql.new("select * from test", "Database/test/select", {}, 1.2), 
               NewRelic::Agent::SlowSql.new("select * from test2", "Database/test2/select", {}, 1.1)
              ]
    data.sql_data.concat(queries)
    @sampler.harvest_slow_sql data   
    sql_traces = @sampler.harvest
    assert_equal(["header0", "header1", "header2"],
                 sql_traces[0].params[:explain_plan][0].sort)
    assert_equal(["header0", "header1", "header2"],
                 sql_traces[1].params[:explain_plan][0].sort)
    assert_equal(["foo0", "foo1", "foo2"],
                 sql_traces[0].params[:explain_plan][1][0].sort)    
    assert_equal(["bar0", "bar1", "bar2"],
                 sql_traces[1].params[:explain_plan][1][0].sort)
  end

  def test_sql_trace_should_include_transaction_guid
    txn_sampler = NewRelic::Agent::TransactionSampler.new
    NewRelic::Agent.instance.stats_engine.transaction_sampler = txn_sampler
    txn_sampler.start_builder(Time.now)
    txn_sampler.notice_transaction('a path', 'a uri', {:some => :params})
    @sampler.create_transaction_data
    @sampler.notice_transaction('a path', 'a uri', {:some => :params})

    assert_equal(NewRelic::Agent.instance.transaction_sampler.builder.sample.guid,
                 NewRelic::Agent.instance.sql_sampler.transaction_data.guid)
  end
  
  def test_should_not_collect_explain_plans_when_disabled
    NewRelic::Control.instance['transaction_tracer'] = { 'explain_enabled' => false }
    data = NewRelic::Agent::TransactionSqlData.new
    data.set_transaction_info("WebTransaction/Controller/c/a", "/c/a", {},
                              'guid')
    
    queries = [
               NewRelic::Agent::SlowSql.new("select * from test",
                                            "Database/test/select", {}, 1.5)
              ]
    data.sql_data.concat(queries)
    @sampler.harvest_slow_sql data   
    sql_traces = @sampler.harvest
    assert_equal(nil, sql_traces[0].params[:explain_plan])
    NewRelic::Control.instance['transaction_tracer'] = { 'explain_enabled' => true }
  end

  def test_sql_id_fits_in_a_mysql_int_11
    sql_trace = NewRelic::Agent::SqlTrace.new("select * from test", 
            NewRelic::Agent::SlowSql.new("select * from test",
                "Database/test/select", {}, 1.2),
        "tx_name", "uri")
    
    assert -2147483648 <= sql_trace.sql_id, "sql_id too small"
    assert 2147483647 >= sql_trace.sql_id, "sql_id too large"
  end

  def test_sends_obfuscated_queries_when_configured
    NewRelic::Control.instance['transaction_tracer'] = { 'record_sql' => 'obfuscated' }
    
    data = NewRelic::Agent::TransactionSqlData.new
    data.set_transaction_info("WebTransaction/Controller/c/a", "/c/a", {},
                              'guid')
    data.sql_data.concat([NewRelic::Agent::SlowSql.new("select * from test where foo = 'bar'",
                                                       "Database/test/select", {}, 1.5), 
                          NewRelic::Agent::SlowSql.new("select * from test where foo in (1,2,3,4,5)",
                                                       "Database/test/select", {}, 1.2)])
    @sampler.harvest_slow_sql(data)      
    sql_traces = @sampler.harvest

    assert_equal('select * from test where foo = ?', sql_traces[0].sql)
    assert_equal('select * from test where foo in (?,?,?,?,?)', sql_traces[1].sql)        
  end
end
