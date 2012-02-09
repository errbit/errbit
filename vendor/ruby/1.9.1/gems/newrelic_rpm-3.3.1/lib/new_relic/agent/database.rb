require 'singleton'

module NewRelic
  # columns for a mysql explain plan
  MYSQL_EXPLAIN_COLUMNS = [
                           "Id",
                           "Select Type",
                           "Table",
                           "Type",
                           "Possible Keys",
                           "Key",
                           "Key Length",
                           "Ref",
                           "Rows",
                           "Extra"
                          ].freeze
  
  module Agent
    module Database
      extend self
      
      def obfuscate_sql(sql)
        Obfuscator.instance.obfuscator.call(sql)
      end
      
      def set_sql_obfuscator(type, &block)
        Obfuscator.instance.set_sql_obfuscator(type, &block)
      end
      
      def get_connection(config)
        ConnectionManager.instance.get_connection(config)
      end
      
      def close_connections
        ConnectionManager.instance.close_connections
      end
      
      # Perform this in the runtime environment of a managed
      # application, to explain the sql statement executed within a
      # segment of a transaction sample. Returns an array of
      # explanations (which is an array rows consisting of an array of
      # strings for each column returned by the the explain query)
      # Note this happens only for statements whose execution time
      # exceeds a threshold (e.g. 500ms) and only within the slowest
      # transaction in a report period, selected for shipment to New
      # Relic
      def explain_sql(sql, connection_config)
        return nil unless sql && connection_config
        statement = sql.split(";\n")[0] # only explain the first
        explain_sql = explain_statement(statement, connection_config)
        return explain_sql || []
      end
      
      def explain_statement(statement, config)
        if is_select?(statement)
          handle_exception_in_explain do
            connection = get_connection(config)
            plan = nil
            if connection
              plan = process_resultset(connection.execute("EXPLAIN #{statement}"))
            end
            return plan
          end
        end
      end
      
      def process_resultset(items)
        # The resultset type varies for different drivers.  Only thing you can count on is
        # that it implements each.  Also: can't use select_rows because the native postgres
        # driver doesn't know that method.
        
        headers = []
        values = []
        if items.respond_to?(:each_hash)
          items.each_hash do |row|
            headers = row.keys
            values << headers.map{|h| row[h] }
          end
        elsif items.respond_to?(:each)
          items.each do |row|
            if row.kind_of?(Hash)
              headers = row.keys
              values << headers.map{|h| row[h] }
            else
              values << row
            end
          end
        else
          values = [items]
        end
        
        headers = nil if headers.empty?
        [headers, values]
      end

      def handle_exception_in_explain
        yield
      rescue Exception => e
        begin
          # guarantees no throw from explain_sql
          NewRelic::Control.instance.log.error("Error getting query plan: #{e.message}")
          NewRelic::Control.instance.log.debug(e.backtrace.join("\n"))
        rescue Exception
          # double exception. throw up your hands
        end
      end
      
      def is_select?(statement)
        # split the string into at most two segments on the
        # system-defined field separator character
        first_word, rest_of_statement = statement.split($;, 2)
        (first_word.upcase == 'SELECT')
      end
      
      class ConnectionManager
        include Singleton

        # Returns a cached connection for a given ActiveRecord
        # configuration - these are stored or reopened as needed, and if
        # we cannot get one, we ignore it and move on without explaining
        # the sql
        def get_connection(config)
          @connections ||= {}
          
          connection = @connections[config]
          
          return connection if connection
          
          begin
            connection = ActiveRecord::Base.send("#{config[:adapter]}_connection", config)
            @connections[config] = connection
          rescue => e
            NewRelic::Agent.agent.log.error("Caught exception #{e} trying to get connection to DB for explain. Control: #{config}")
            NewRelic::Agent.agent.log.error(e.backtrace.join("\n"))
            nil
          end
        end
        
        # Closes all the connections in the internal connection cache
        def close_connections
          @connections ||= {}
          @connections.values.each do |connection|
            begin
              connection.disconnect!
            rescue
            end
          end
          
          @connections = {}
        end
      end

      class Obfuscator
        include Singleton
        
        attr_reader :obfuscator
        
        def initialize
          reset
        end

        def reset
          @obfuscator = method(:default_sql_obfuscator)
        end
        
        # Sets the sql obfuscator used to clean up sql when sending it
        # to the server. Possible types are:
        #
        # :before => sets the block to run before the existing
        # obfuscators
        #
        # :after => sets the block to run after the existing
        # obfuscator(s)
        #
        # :replace => removes the current obfuscator and replaces it
        # with the provided block
        def set_sql_obfuscator(type, &block)
          if type == :before
            @obfuscator = NewRelic::ChainedCall.new(block, @obfuscator)
          elsif type == :after
            @obfuscator = NewRelic::ChainedCall.new(@obfuscator, block)
          elsif type == :replace
            @obfuscator = block
          else
            fail "unknown sql_obfuscator type #{type}"
          end
        end
        
        def default_sql_obfuscator(sql)
          sql = sql.dup
          # This is hardly readable.  Use the unit tests.
          # remove single quoted strings:
          sql.gsub!(/'(.*?[^\\'])??'(?!')/, '?')
          # remove double quoted strings:
          sql.gsub!(/"(.*?[^\\"])??"(?!")/, '?')
          # replace all number literals
          sql.gsub!(/\d+/, "?")
          sql
        end
      end
    end
  end
end
