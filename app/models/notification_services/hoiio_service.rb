class NotificationServices::HoiioService < NotificationService
  Label = "hoiio"
  Fields += [
      [:api_token, {
          :placeholder => "App ID",
          :label => "App ID"
      }],
      [:subdomain, {
          :placeholder => "Access Token",
          :label => "Access Token"
      }],
      [:room_id, {
          :placeholder => "+6511111111, +6511111111",
          :label       => "Recipient's phone numbers seperated by comma. Phone numbers should start with a \"+\" and country code."
      }]
  ]


  def url
    "https://secure.hoiio.com/user/"
  end

  def create_notification(message_info)
    sms = Hoi::SMS.new(api_token, subdomain)

    room_id.split(',').each do |number|
      sms.send :dest => number, :msg => form_message(message_info)
    end
  end

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify your App ID, Access Token and Recipient\'s phone numbers'
    end
  end

  private

  def problem_description(problem)
    "[#{problem.environment}]#{problem.message.to_s.truncate(50)}"
  end

  def problem_message(problem)
    "#{problem_url(problem)} #{problem_description(problem)}"
  end
end
