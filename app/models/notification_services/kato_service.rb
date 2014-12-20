class NotificationServices::KatoService < NotificationService
  Label = 'kato'
  Fields += [
    [:api_token, {
      :placeholder => 'Kato Integration Token',
      :label => 'Token'
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? unless f[0] == :color }
      errors.add :base, 'You must specify your Kato token.'
    end
  end

  def url
    "https://api.kato.im/rooms/#{api_token}/simple"
  end

  def format_message(problem)
    "**#{problem.error_class}**\n**[#{problem.app.name}]** [#{problem.environment}] *[#{problem.where}]*:\n[Take a look](#{problem_url(problem)})"
  end

  def post_payload(problem)
    {
      :from => 'Errbit',
      :renderer => 'markdown',
      :text => format_message(problem),
      :color => 'red'
    }.to_json
  end

  def create_notification(problem)
    HTTParty.post(url, :body => post_payload(problem), :headers => { 'Content-Type' => 'application/json' })
  end
end
