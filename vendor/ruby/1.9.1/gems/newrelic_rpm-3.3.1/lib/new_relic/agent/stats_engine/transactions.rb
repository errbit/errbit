# -*- coding: utf-8 -*-
module NewRelic
module Agent
  class StatsEngine
    # A simple stack element that tracks the current name and length
    # of the executing stack
    class ScopeStackElement
      attr_reader :name, :deduct_call_time_from_parent
      attr_accessor :children_time
      def initialize(name, deduct_call_time)
        @name = name
        @deduct_call_time_from_parent = deduct_call_time
        @children_time = 0
      end
    end
    
    # Handles pushing and popping elements onto an internal stack that
    # tracks where time should be allocated in Transaction Traces
    module Transactions
      
      # Defines methods that stub out the stats engine methods
      # when the agent is disabled
      module Shim # :nodoc:
        def start_transaction(*args); end
        def end_transaction; end
        def push_scope(*args); end
        def transaction_sampler=(*args); end
        def scope_name=(*args); end
        def scope_name; end
        def pop_scope(*args); end
      end
      
      # add a new transaction sampler, unless we're currently in a
      # transaction (then we fail)
      def transaction_sampler= sampler
        fail "Can't add a scope listener midflight in a transaction" if scope_stack.any?
        @transaction_sampler = sampler
      end
      
      # removes a transaction sampler
      def remove_transaction_sampler(l)
        @transaction_sampler = nil
      end
      
      # Pushes a scope onto the transaction stack - this generates a
      # TransactionSample::Segment at the end of transaction execution
      def push_scope(metric, time = Time.now.to_f, deduct_call_time_from_parent = true)
        stack = scope_stack
        stack.empty? ? GCProfiler.init : GCProfiler.capture
        @transaction_sampler.notice_push_scope metric, time if @transaction_sampler
        scope = ScopeStackElement.new(metric, deduct_call_time_from_parent)
        stack.push scope
        scope
      end
      
      # Pops a scope off the transaction stack - this updates the
      # transaction sampler that we've finished execution of a traced method
      def pop_scope(expected_scope, duration, time=Time.now.to_f)
        GCProfiler.capture
        stack = scope_stack
        scope = stack.pop
        fail "unbalanced pop from blame stack, got #{scope ? scope.name : 'nil'}, expected #{expected_scope ? expected_scope.name : 'nil'}" if scope != expected_scope

        if !stack.empty?
          if scope.deduct_call_time_from_parent
            stack.last.children_time += duration
          else
            stack.last.children_time += scope.children_time
          end
        end
        @transaction_sampler.notice_pop_scope(scope.name, time) if @transaction_sampler
        scope
      end
      
      # Returns the latest ScopeStackElement
      def peek_scope
        scope_stack.last
      end

      # set the name of the transaction for the current thread, which will be used
      # to define the scope of all traced methods called on this thread until the
      # scope stack is empty.
      #
      # currently the transaction name is the name of the controller action that
      # is invoked via the dispatcher, but conceivably we could use other transaction
      # names in the future if the traced application does more than service http request
      # via controller actions
      def scope_name=(transaction)
        Thread::current[:newrelic_scope_name] = transaction
      end
      
      # Returns the current scope name from the thread local
      def scope_name
        Thread::current[:newrelic_scope_name]
      end

      # Start a new transaction, unless one is already in progress
      def start_transaction(name = nil)
        Thread::current[:newrelic_scope_stack] ||= []
        self.scope_name = name if name
      end

      # Try to clean up gracefully, otherwise we leave things hanging around on thread locals.
      # If it looks like a transaction is still in progress, then maybe this is an inner transaction
      # and is ignored.
      #
      def end_transaction
        stack = scope_stack

        if stack && stack.empty?
          Thread::current[:newrelic_scope_stack] = nil
          Thread::current[:newrelic_scope_name] = nil
        end
      end

      private
      
      # Returns the current scope stack, memoized to a thread local variable
      def scope_stack
        Thread::current[:newrelic_scope_stack] ||= []
      end
    end
  end
end
end
