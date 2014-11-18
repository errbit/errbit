class NotificationServices::ImessageService < NotificationService
  Label = "imessage"
  Fields = [
    [:api_token, {
      :placeholder => 'iMessage accounts to send the notification to. Separated by ;',
      :label => 'account'
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify the iMessage account'
    end
  end

  def message(problem)
    "[#{problem.app.name}][#{problem.environment}][#{problem.where}]: #{problem.error_class} #{problem_url(problem)}"
  end

  def create_notification(problem)
    Imessage::Sender.send(:message => message(problem), :contacts => api_token.split(';'))
  end
end
