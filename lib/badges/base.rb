module Badges
  class Base
    include ActiveSupport::DescendantsTracker

    class << self
      attr_accessor :title

      def key
        name.underscore.split('/').last
      end

      def find_badge_for_key(key)
        descendants.find { |badge_class| badge_class.key == key }
      end
    end

    COLORS = {
      green:  '#4c1',
      red:    '#e05d44',
      yellow: '#dfb317',
      grey:   '#9f9f9f'
    }.freeze

    def initialize(app)
      @app = app
    end

    def key_color
      '#555'
    end

    def key_text_anchor
      key_width / 2
    end

    def value_text_anchor
      key_width + (value_width / 2)
    end

    def width
      key_width + value_width
    end

    def key_width
      raise NotImplementedError
    end

    def key_text
      raise NotImplementedError
    end

    def value_color
      raise NotImplementedError
    end

    def value_text
      raise NotImplementedError
    end
  end
end
