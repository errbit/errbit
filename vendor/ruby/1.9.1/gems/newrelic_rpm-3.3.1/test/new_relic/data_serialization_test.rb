require File.expand_path(File.join(File.dirname(__FILE__),'..', 'test_helper'))
require 'new_relic/data_serialization'
class NewRelic::DataSerializationTest < Test::Unit::TestCase

  attr_reader :file, :path
  
  def setup
    NewRelic::Control.instance['log_file_path'] = './log'
    @path = NewRelic::Control.instance.log_path
    @file = "#{path}/newrelic_agent_store.db"
    Dir.mkdir(path) if !File.directory?(path)
    FileUtils.rm_rf(@file)
    FileUtils.rm_rf("#{@path}/newrelic_agent_store.pid")
  end
  
  def teardown
    # this gets set to true in some tests
    NewRelic::Control.instance['disable_serialization'] = false
    mocha_teardown
  end
  
  def test_read_and_write_from_file_read_only
    File.open(file, 'w') do |f|
      f.write(Marshal.dump('a happy string'))
    end
    NewRelic::DataSerialization.read_and_write_to_file do |data|
      assert_equal('a happy string', data, "should pull the dumped item from the file")
      nil # must explicitly return nil or the return value will be dumped
    end
    assert_equal(0, File.size(file), "Should not leave any data in the file")
  end

  def test_bad_paths
    NewRelic::Control.instance.stubs(:log_path).returns("/bad/path")
    assert NewRelic::DataSerialization.should_send_data?
    NewRelic::DataSerialization.read_and_write_to_file do
      'a happy string'
    end
    assert !File.exists?(file)
  end
  
  def test_read_and_write_to_file_dumping_contents
    expected_contents = Marshal.dump('a happy string')
    NewRelic::DataSerialization.read_and_write_to_file do
      'a happy string'
    end
    assert_equal(expected_contents, File.read(file), "should have dumped the contents")
  end

  def test_read_and_write_to_file_yields_old_data
    expected_contents = 'a happy string'
    File.open(file, 'w') do |f|
      f.write(Marshal.dump(expected_contents))
    end
    contents = nil
    NewRelic::DataSerialization.read_and_write_to_file do |old_data|
      contents = old_data
      'a happy string'
    end
    assert_equal(contents, expected_contents, "should have dumped the contents")
  end

  def test_read_and_write_to_file_round_trip
    old_data = nil
    NewRelic::DataSerialization.read_and_write_to_file do |data|
      old_data = data
      'a' * 30
    end
    NewRelic::DataSerialization.read_and_write_to_file do |data|
      assert_equal('a'*30, data, "should be the same after serialization")
    end
  end

  def test_should_send_data_when_over_limit
    NewRelic::DataSerialization.stubs(:max_size).returns(20)
    NewRelic::DataSerialization.read_and_write_to_file do
      "a" * 30
    end
    assert(NewRelic::DataSerialization.should_send_data?, 'Should be over limit')
  end

  def test_read_until_eoferror
    File.open(file, 'w') do |f|
      f.write("a" * 10_001)
    end
    value = ""
    File.open(file,'r') do |f|
      value << NewRelic::DataSerialization.instance_eval { read_until_eof_error(f) }
    end
    assert_equal('a' * 10_001, value, "should retrieve all the contents from the string and not raise EOFerrors")
  end
  
  def test_write_contents_nonblockingly
    File.open(file, 'w') do |f|
      f.write("") # write nothing! NOTHING
    end

    File.open(file, 'w') do |f|
      NewRelic::DataSerialization.instance_eval { write_contents_nonblockingly(f, 'a' * 10_001) }
    end
    value = File.read(file)
    assert_equal('a' * 10_001, value, "should write a couple thousand 'a's to a file without exploding")
  end

  def test_should_send_data_disabled
    NewRelic::Control.instance.disable_serialization = true
    assert(NewRelic::DataSerialization.should_send_data?,
           'should send data when disabled')
  end

  def test_should_send_data_under_limit
    NewRelic::DataSerialization.expects(:max_size).returns(2000)
    NewRelic::DataSerialization.read_and_write_to_file do |old_data|
      "a" * 5
    end
    
    assert(!NewRelic::DataSerialization.store_too_large?,
           'Should be under the limit')
  end

  def test_should_handle_empty_spool_file
    NewRelic::Control.instance.log.expects(:error).never
    assert_nil NewRelic::DataSerialization.instance_eval { load('') }
  end

  def test_spool_file_location_respects_log_file_path_setting
    NewRelic::Control.instance.expects(:log_path).returns('./tmp')
    Dir.mkdir('./tmp') if !File.directory?('./tmp')
    NewRelic::DataSerialization.read_and_write_to_file do |_|
      'a' * 30
    end
    assert(File.exists?('./tmp/newrelic_agent_store.db'),
           "Spool file not created at user specified location")
  end

  def test_age_file_location_respects_log_file_path_setting
    NewRelic::Control.instance.expects(:log_path).returns('./tmp')
    Dir.mkdir('./tmp') if !File.directory?('./tmp')
    NewRelic::DataSerialization.update_last_sent!
    assert(File.exists?('./tmp/newrelic_agent_store.pid'),
           "Age file not created at user specified location")
  end
  
  def test_pid_age_creates_pid_file_if_none_exists
    assert(!File.exists?("#{@path}/newrelic_agent_store.pid"),
           'pid file found, should not be there')
    assert(!NewRelic::DataSerialization.pid_too_old?,
           "new pid should not be too old")
    assert(File.exists?("#{@path}/newrelic_agent_store.pid"),
           'pid file not found, should be there')
  end

  def test_loading_does_not_seg_fault_if_gc_triggers
    return if NewRelic::LanguageSupport.using_version?('1.8.6')
    require 'timeout'
    
    Thread.abort_on_exception = true
    rcv,snd = IO.pipe
    
    write = Thread.new do
      obj = ('a'..'z').inject({}){|h,s|h[s.intern]=s*1024;h}
      data = Marshal.dump(obj)
      snd.write(data[0,data.size/2])
      sleep(0.1)
      snd.write(data[(data.size/2)..-1])
      snd.close
    end
    
    read = Thread.new do
      lock = Mutex.new
      lock.synchronize do
        NewRelic::DataSerialization.class_eval { load(rcv) }
      end
    end

    gc = Thread.new do
      10.times do
        GC.start
      end
    end

    Timeout::timeout(5) do
      write.join
      read.join
      gc.join
    end
    # should not seg fault
  end

  def test_dump_should_be_thread_safe
    stats_hash = {}

    2000.times do |i|
      stats_hash[i.to_s] = NewRelic::StatsBase.new
    end
        
    harvest = Thread.new do
      NewRelic::DataSerialization.class_eval { dump(stats_hash) }
    end
    
    app = Thread.new do
      stats_hash["a"] = NewRelic::StatsBase.new
    end
    
    assert_nothing_raised do
      [app, harvest].each{|t| t.join}
    end    
  end
end
