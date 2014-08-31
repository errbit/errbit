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

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify your App ID, Access Token and Recipient\'s phone numbers'
    end
  end

  def url
    "https://secure.hoiio.com/user/"
  end

  def notification_description(problem)
    "[#{ problem.environment }]#{problem.message.to_s.truncate(50)}"
  end

  def create_notification(problem)
    # build the hoi client
    sms = Hoi::SMS.new(api_token, subdomain)

    # send sms
    room_id.split(',').each do |number|
      sms.send :dest => number, :msg => "#{Errbit::Config.protocol}://#{Errbit::Config.host}/apps/#{problem.app.id.to_s} #{notification_description problem}"
    end

  end
end
