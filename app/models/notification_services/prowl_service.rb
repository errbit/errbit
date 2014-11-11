if defined? Prowl
  class NotificationServices::ProwlService < NotificationService
    Label = 'prowl'
    Fields += [
      [:api_token, {
        :placeholder => "API Token"
      }],
      [:priority, {
        :label       => 'Priorty (-2 to +2)',
        :placeholder => "0"
      }],
    ]

    def check_params
      if Fields.any? { |f, _| self[f].blank? }
        errors.add :base, 'You must specify your Prowl API key and event priority'
      end
    end

    def url
      "http://www.prowlapp.com"
    end

    def create_notification(problem)
      url = app_problem_url problem.app, problem

      Prowl.add(
        :apikey => api_token,
        :application => "#{problem.app.name} (#{problem.environment})",
        :event => problem.where,
          :description => problem.message.to_s.truncate(100),
          :url => url,
          :priority => priority
      )
    end
  end
end
