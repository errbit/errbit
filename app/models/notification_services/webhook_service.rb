class NotificationServices::WebhookService < NotificationService
  Label = "webhook"
  Fields = [
    [:api_token, {
      :placeholder => 'URL to receive a POST request when an error occurs',
      :label => 'URL'
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify the URL'
    end
  end

  def create_notification(problem)
    HTTParty.post(api_token, :body => {:problem => problem.to_json})
  end
end
