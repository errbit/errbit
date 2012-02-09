require 'new_relic/transaction_sample'
module NewRelic
  class TransactionSample
    class Segment
      attr_reader :entry_timestamp
      # The exit timestamp will be relative except for the outermost sample which will
      # have a timestamp.
      attr_reader :exit_timestamp
      attr_reader :parent_segment
      attr_reader :metric_name
      attr_reader :segment_id

      def initialize(timestamp, metric_name, segment_id)
        @entry_timestamp = timestamp
        @metric_name = metric_name || '<unknown>'
        @segment_id = segment_id || object_id
      end
      
      # sets the final timestamp on a segment to indicate the exit
      # point of the segment
      def end_trace(timestamp)
        @exit_timestamp = timestamp
      end
      
      def add_called_segment(s)
        @called_segments ||= []
        @called_segments << s
        s.parent_segment = self
      end

      def to_s
        to_debug_str(0)
      end

      def to_json(options={})
        hash = {
          :entry_timestamp => @entry_timestamp,
          :exit_timestamp => @exit_timestamp,
          :metric_name => @metric_name,
          :segment_id => @segment_id,
        }

        hash[:called_segments] = called_segments if !called_segments.empty?
        hash[:params] = @params if @params && !@params.empty?

        hash.to_json
      end

      def path_string
        "#{metric_name}[#{called_segments.collect {|segment| segment.path_string }.join('')}]"
      end
      def to_s_compact
        str = ""
        str << metric_name
        if called_segments.any?
          str << "{#{called_segments.map { | cs | cs.to_s_compact }.join(",")}}"
        end
        str
      end
      def to_debug_str(depth)
        tab = "  " * depth
        s = tab.clone
        s << ">> #{'%3i ms' % (@entry_timestamp*1000)} [#{self.class.name.split("::").last}] #{metric_name} \n"
        unless params.empty?
          params.each do |k,v|
            s << "#{tab}    -#{'%-16s' % k}: #{v.to_s[0..80]}\n"
          end
        end
        called_segments.each do |cs|
          s << cs.to_debug_str(depth + 1)
        end
        s << tab + "<< "
        s << case @exit_timestamp
             when nil then ' n/a'
             when Numeric then '%3i ms' % (@exit_timestamp*1000)
             else @exit_timestamp.to_s
             end
        s << " #{metric_name}\n"
      end

      def called_segments
        @called_segments || []
      end

      # return the total duration of this segment
      def duration
        (@exit_timestamp - @entry_timestamp).to_f
      end

      # return the duration of this segment without
      # including the time in the called segments
      def exclusive_duration
        d = duration

        called_segments.each do |segment|
          d -= segment.duration
        end
        d
      end
      def count_segments
        count = 1
        called_segments.each { | seg | count  += seg.count_segments }
        count
      end
      # Walk through the tree and truncate the segments in a
      # depth-first manner
      def truncate(max)
        return 1 unless @called_segments
        total, self.called_segments = truncate_each_child(max - 1)
        total+1
      end

      def truncate_each_child(max)
        total = 0
        accumulator = []
        called_segments.each { | s |
          if total == max
            true
          else
            total += s.truncate(max - total)
            accumulator << s
          end
        }
        total
        [total, accumulator]
      end

      def []=(key, value)
        # only create a parameters field if a parameter is set; this will save
        # bandwidth etc as most segments have no parameters
        params[key] = value
      end

      def [](key)
        params[key]
      end

      def params
        @params ||= {}
      end

      # call the provided block for this segment and each
      # of the called segments
      def each_segment(&block)
        block.call self

        if @called_segments
          @called_segments.each do |segment|
            segment.each_segment(&block)
          end
        end
      end

      # call the provided block for this segment and each
      # of the called segments while keeping track of nested segments
      def each_segment_with_nest_tracking(&block)
        summary = block.call self
        summary.current_nest_count += 1 if summary

        if @called_segments
          @called_segments.each do |segment|
            segment.each_segment_with_nest_tracking(&block)
          end
        end

        summary.current_nest_count -= 1 if summary
      end

      def find_segment(id)
        return self if @segment_id == id
        called_segments.each do |segment|
          found = segment.find_segment(id)
          return found if found
        end
        nil
      end
      
      def explain_sql
        NewRelic::Agent::Database.explain_sql(params[:sql],
                                              params[:connection_config])
      end
      
      def obfuscated_sql
        NewRelic::Agent::Database.obfuscate_sql(params[:sql])
      end
      
      def params=(p)
        @params = p
      end

      def called_segments=(segments)
        @called_segments = segments
      end

      protected
      def parent_segment=(s)
        @parent_segment = s
      end
    end
  end
end
