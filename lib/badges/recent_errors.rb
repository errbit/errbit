module Badges
  class RecentErrors < Base
    self.title = 'Problems in last 24h'

    def key_width
      62
    end

    def value_width
      40
    end

    def value_color
      case problem_count
      when 0..1 then COLORS[:green]
      when 2..10 then COLORS[:yellow]
      else COLORS[:red]
      end
    end

    def value_text
      @problem_count
    end

    def key_text
      "# in 24h"
    end

  private

    def problem_count
      @problem_count ||= @app.problems.unresolved.where(:last_notice_at.gte => 24.hours.ago).count
    end
  end
end
