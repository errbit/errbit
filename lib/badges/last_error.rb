module Badges
  class LastError < Base
    self.title = 'Last unresolved error'

    def key_width
      62
    end

    def value_width
      40
    end

    def value_color
      from, to = Errbit::Config.badge_last_error_steps.presence || [24, 48]
      if last_notice.blank?
        Base::COLORS[:grey]
      else
        case hours_till_last_notice
        when 0..from then Base::COLORS[:red]
        when from..to then Base::COLORS[:yellow]
        else Base::COLORS[:green]
        end
      end
    end

    def value_text
      if last_notice.nil?
        "n/a"
      elsif hours_till_last_notice < 1
        "<1h"
      elsif hours_till_last_notice < 24
        "#{hours_till_last_notice.round}h"
      elsif hours_till_last_notice < (30.days / 1.hour)
        "#{(hours_till_last_notice / 24).round}d"
      else
        ">30d"
      end
    end

    def key_text
      "last error"
    end

  private

    def hours_till_last_notice
      @hours_till_last_notice ||=
        (Time.zone.now - last_notice) / 1.hour
    end

    def last_notice
      @last_notice ||= @app.problems.unresolved.max('last_notice_at')
    end
  end
end
