require 'new_relic/metric_parser'
module NewRelic
  module MetricParser
    class MemCache < NewRelic::MetricParser::MetricParser
      def is_memcache?; true; end

      # for Memcache metrics, the short name is actually
      # the full name
      def short_name
        'Memcache'
      end
      def developer_name
        "Memcache #{segments[1..-1].join '/'}"
      end

      def all?
        segments[1].index('all') == 0
      end
      def operation
        all? ? 'All Operations' : segments[1]
      end
      def legend_name
        case segments[1]
        when 'allWeb'
          "Memcache"
        when 'allOther'
          "Non-web Memcache"
        else
          "Memcache #{operation} operations"
        end
      end
      def tooltip_name
        case segments[1]
        when 'allWeb'
          "Memcache calls from web transactions"
        when 'allOther'
          "Memcache calls from non-web transactions"
        else
          "MemCache #{operation} operations"
        end

      end
      def developer_name
        case segments[1]
        when 'allWeb'
          "Web Memcache"
        when 'allOther'
          "Non-web Memcache"
        else
          "Memcache #{operation}"
        end
      end
    end
  end
end
