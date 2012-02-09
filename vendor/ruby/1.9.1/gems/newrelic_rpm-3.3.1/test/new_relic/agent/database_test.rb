require File.expand_path(File.join(File.dirname(__FILE__), '..', '..',
                                   'test_helper'))
require 'new_relic/agent/database'
class NewRelic::Agent::DatabaseTest < Test::Unit::TestCase
  def teardown
    NewRelic::Agent::Database::Obfuscator.instance.reset
  end
  
  def test_process_resultset
    resultset = [["column"]]
    assert_equal([nil, [["column"]]],
                 NewRelic::Agent::Database.process_resultset(resultset))
  end
  
  def test_explain_sql_select_with_mysql_connection
    config = {:adapter => 'mysql'}
    config.default('val')
    sql = 'SELECT foo'
    connection = mock('connection')
    plan = {
      "select_type"=>"SIMPLE", "key_len"=>nil, "table"=>"blogs", "id"=>"1",
      "possible_keys"=>nil, "type"=>"ALL", "Extra"=>"", "rows"=>"2",
      "ref"=>nil, "key"=>nil
    }
    result = mock('explain plan')
    result.expects(:each_hash).yields(plan)
    # two rows, two columns
    connection.expects(:execute).with('EXPLAIN SELECT foo').returns(result)
    NewRelic::Agent::Database.expects(:get_connection).with(config).returns(connection)

    result = NewRelic::Agent::Database.explain_sql(sql, config)
    assert_equal(plan.keys.sort, result[0].sort)
    assert_equal(plan.values.compact.sort, result[1][0].compact.sort)    
  end

  def test_explain_sql_one_select_with_pg_connection
    config = {:adapter => 'postgresql'}
    config.default('val')
    sql = 'select count(id) from blogs limit 1'
    connection = mock('connection')
    plan = [{"QUERY PLAN"=>"Limit  (cost=11.75..11.76 rows=1 width=4)"},
            {"QUERY PLAN"=>"  ->  Aggregate  (cost=11.75..11.76 rows=1 width=4)"},
            {"QUERY PLAN"=>"        ->  Seq Scan on blogs  (cost=0.00..11.40 rows=140 width=4)"}]
    connection.expects(:execute).returns(plan)
    NewRelic::Agent::Database.expects(:get_connection).with(config).returns(connection)
    assert_equal([['QUERY PLAN'],
                  [["Limit  (cost=11.75..11.76 rows=1 width=4)"],
                   ["  ->  Aggregate  (cost=11.75..11.76 rows=1 width=4)"],
                   ["        ->  Seq Scan on blogs  (cost=0.00..11.40 rows=140 width=4)"]]],
                 NewRelic::Agent::Database.explain_sql(sql, config))
  end

  def test_explain_sql_no_sql
    assert_equal(nil, NewRelic::Agent::Database.explain_sql(nil, nil))
  end

  def test_explain_sql_no_connection_config
    assert_equal(nil, NewRelic::Agent::Database.explain_sql('select foo', nil))
  end

  def test_explain_sql_non_select
    assert_equal([], NewRelic::Agent::Database.explain_sql('foo',
                                                           mock('config')))
  end

  def test_explain_sql_one_select_no_connection
    # NB this test raises an error in the log, much as it might if a
    # user supplied a config that was not valid. This is generally
    # expected behavior - the get_connection method shouldn't allow
    # errors to percolate up.
    config = mock('config')
    config.stubs(:[]).returns(nil)
    assert_equal([], NewRelic::Agent::Database.explain_sql('SELECT', config))
  end  
  
  def test_handle_exception_in_explain
    fake_error = Exception.new('a message')
    NewRelic::Control.instance.log.expects(:error).with('Error getting query plan: a message')
    # backtrace can be basically any string, just should get logged
    NewRelic::Control.instance.log.expects(:debug).with(instance_of(String))
    
    NewRelic::Agent::Database.handle_exception_in_explain do
      raise(fake_error)
    end
  end

  def test_sql_normalization
    # basic statement
    assert_equal "INSERT INTO X values(?,?, ? , ?)",
    NewRelic::Agent::Database.obfuscate_sql("INSERT INTO X values('test',0, 1 , 2)")

    # escaped literals
    assert_equal "INSERT INTO X values(?, ?,?, ? , ?)",
    NewRelic::Agent::Database.obfuscate_sql("INSERT INTO X values('', 'jim''s ssn',0, 1 , 'jim''s son''s son')")
    
    # multiple string literals
    assert_equal "INSERT INTO X values(?,?,?, ? , ?)",
    NewRelic::Agent::Database.obfuscate_sql("INSERT INTO X values('jim''s ssn','x',0, 1 , 2)")
    
    # empty string literal
    # NOTE: the empty string literal resolves to empty string, which for our purposes is acceptable
    assert_equal "INSERT INTO X values(?,?,?, ? , ?)",
    NewRelic::Agent::Database.obfuscate_sql("INSERT INTO X values('','x',0, 1 , 2)")
    
    # try a select statement
    assert_equal "select * from table where name=? and ssn=?",
    NewRelic::Agent::Database.obfuscate_sql("select * from table where name='jim gochee' and ssn=0012211223")
    
    # number literals embedded in sql - oh well
    assert_equal "select * from table_? where name=? and ssn=?",
    NewRelic::Agent::Database.obfuscate_sql("select * from table_007 where name='jim gochee' and ssn=0012211223")
  end
  
  def test_sql_normalization__single_quotes
    assert_equal "INSERT ? into table",
    NewRelic::Agent::Database.obfuscate_sql("INSERT 'this isn''t a real value' into table")
    assert_equal "INSERT ? into table",
    NewRelic::Agent::Database.obfuscate_sql(%q[INSERT '"' into table])
    assert_equal "INSERT ? into table",
    NewRelic::Agent::Database.obfuscate_sql(%q[INSERT ' "some text" \" ' into table])
    #    could not get this one licked.  no biggie
    #    assert_equal "INSERT ? into table",
    #    @agent.send(:default_sql_obfuscator, %q[INSERT '\'' into table])
    assert_equal "INSERT ? into table",
    NewRelic::Agent::Database.obfuscate_sql(%q[INSERT ''' ' into table])
  end

  def test_sql_normalization__double_quotes
    assert_equal "INSERT ? into table",
    NewRelic::Agent::Database.obfuscate_sql(%q[INSERT "this isn't a real value" into table])
    assert_equal "INSERT ? into table",
    NewRelic::Agent::Database.obfuscate_sql(%q[INSERT "'" into table])
    assert_equal "INSERT ? into table",
    NewRelic::Agent::Database.obfuscate_sql(%q[INSERT " \" " into table])
    assert_equal "INSERT ? into table",
    NewRelic::Agent::Database.obfuscate_sql(%q[INSERT " 'some text' " into table])
  end
  
  def test_sql_obfuscation_filters
    NewRelic::Agent::Database.set_sql_obfuscator(:replace) do |string|
      "1" + string
    end
    
    sql = "SELECT * FROM TABLE 123 'jim'"
    
    assert_equal "1" + sql, NewRelic::Agent::Database.obfuscate_sql(sql)
    
    NewRelic::Agent::Database.set_sql_obfuscator(:before) do |string|
      "2" + string
    end
    
    assert_equal "12" + sql, NewRelic::Agent::Database.obfuscate_sql(sql)
    
    NewRelic::Agent::Database.set_sql_obfuscator(:after) do |string|
      string + "3"
    end
    
    assert_equal "12" + sql + "3", NewRelic::Agent::Database.obfuscate_sql(sql)

    NewRelic::Agent::Database::Obfuscator.instance.reset
  end
end
