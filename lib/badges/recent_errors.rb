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
      from, to = Errbit::Config.badge_last_error_steps.presence || [1, 10]
      case problem_count
      when 0..from then COLORS[:green]
      when from..to then COLORS[:yellow]
      else COLORS[:red]
      end
    end

    def value_text
      @problem_count
    end

    def key_text
      "# Err/#{hours}"
    end

  private

    def hours
      (Errbit::Config.badge_recent_error_hours || 24).to_i
    end

    def problem_count
      @problem_count ||= @app.problems.unresolved.where(:last_notice_at.gte => hours.hours.ago).count
    end
  end
end
