require File.expand_path(File.join(File.dirname(__FILE__),'..','..','test_helper'))
module NewRelic
  module Agent
    class AgentTest < Test::Unit::TestCase

      def setup
        super
        @agent = NewRelic::Agent::Agent.new
      end

      def test_save_or_transmit_data_should_save
        NewRelic::Agent.expects(:save_data).once
        @agent.expects(:harvest_and_send_timeslice_data).never
        NewRelic::DataSerialization.expects(:should_send_data?).returns(false)
        @agent.instance_eval { save_or_transmit_data }
      end
      
      def test_save_or_transmit_data_should_transmit
        NewRelic::Agent.expects(:load_data)
        @agent.expects(:harvest_and_send_timeslice_data)
        @agent.expects(:harvest_and_send_slowest_sample)
        @agent.expects(:harvest_and_send_errors)
        NewRelic::DataSerialization.expects(:should_send_data?).returns(true)
        @agent.instance_eval { save_or_transmit_data }
      end
      
      def test_serialize
        assert_equal([{}, [], []], @agent.send(:serialize), "should return nil when shut down")
      end

      def test_harvest_transaction_traces
        assert_equal([], @agent.send(:harvest_transaction_traces), 'should return transaction traces')
      end

      def test_harvest_timeslice_data
        assert_equal({}, @agent.send(:harvest_timeslice_data),
                     'should return timeslice data')
      end

      def test_harvest_timelice_data_should_be_thread_safe
        2000.times do |i|
          @agent.stats_engine.stats_hash[i.to_s] = NewRelic::StatsBase.new
        end
        
        harvest = Thread.new do
          @agent.send(:harvest_timeslice_data)
        end

        app = Thread.new do
          @agent.stats_engine.stats_hash["a"] = NewRelic::StatsBase.new
        end
        
        assert_nothing_raised do
          [app, harvest].each{|t| t.join}
        end
      end

      def test_harvest_errors
        assert_equal([], @agent.send(:harvest_errors), 'should return errors')
      end

      def test_merge_data_from_empty
        unsent_timeslice_data = mock('unsent timeslice data')
        unsent_errors = mock('unsent errors')
        unsent_traces = mock('unsent traces')
        @agent.instance_eval {
          @unsent_errors = unsent_errors
          @unsent_timeslice_data = unsent_timeslice_data
          @traces = unsent_traces
        }
        # nb none of the others should receive merge requests
        @agent.merge_data_from([{}])
      end

      def test_unsent_errors_size_empty
        @agent.instance_eval {
          @unsent_errors = nil
        }
        assert_equal(nil, @agent.unsent_errors_size)
      end

      def test_unsent_errors_size_with_errors
        @agent.instance_eval {
          @unsent_errors = ['an error']
        }
        assert_equal(1, @agent.unsent_errors_size)
      end
      
      def test_unsent_traces_size_empty
        @agent.instance_eval {
          @traces = nil
        }
        assert_equal(nil, @agent.unsent_traces_size)
      end

      def test_unsent_traces_size_with_traces
        @agent.instance_eval {
          @traces = ['a trace']
        }
        assert_equal(1, @agent.unsent_traces_size)
      end

      def test_unsent_timeslice_data_empty
        @agent.instance_eval {
          @unsent_timeslice_data = nil
        }
        assert_equal(0, @agent.unsent_timeslice_data, "should have zero timeslice data to start")
        assert_equal({}, @agent.instance_variable_get('@unsent_timeslice_data'), "should initialize the timeslice data to an empty hash if it is empty")
      end

      def test_unsent_timeslice_data_with_errors
        @agent.instance_eval {
          @unsent_timeslice_data = {:key => 'value'}
        }
        assert_equal(1, @agent.unsent_timeslice_data, "should have the key from above")
      end
      
      def test_merge_data_from_all_three_empty
        unsent_timeslice_data = mock('unsent timeslice data')
        unsent_errors = mock('unsent errors')
        unsent_traces = mock('unsent traces')
        @agent.instance_eval {
          @unsent_errors = unsent_errors
          @unsent_timeslice_data = unsent_timeslice_data
          @traces = unsent_traces
        }
        unsent_errors.expects(:+).with([])
        unsent_traces.expects(:+).with([])
        @agent.merge_data_from([{}, [], []])
      end

      def test_should_not_log_log_file_location_if_no_log_file
        NewRelic::Control.instance.stubs(:log_file).returns('/vasrkjn4b3b4')
        @agent.expects(:log).never
        @agent.notify_log_file_location
      end
    end
  end
end
