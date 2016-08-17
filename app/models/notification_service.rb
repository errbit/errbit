class NotificationService < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  default_url_options[:host] = ActionMailer::Base.default_url_options[:host]
  default_url_options[:port] = ActionMailer::Base.default_url_options[:port]

  serialize :notify_at_notices, JSON

  belongs_to :app, inverse_of: :notification_service

  validate :check_params

  if Errbit::Config.per_app_notify_at_notices
    Fields = [[:notify_at_notices,
               { placeholder: 'comma separated numbers or simply 0 for every notice',
                 label: 'notify on errors (0 for all errors)'
               }
              ]]
  else
    Fields = []
  end

  def notify_at_notices
    Errbit::Config.per_app_notify_at_notices ? super : Errbit::Config.notify_at_notices
  end

  # Subclasses are responsible for overwriting this method.
  def check_params; true; end

  def notification_description(problem)
    "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s.truncate(100)}"
  end

  def url; nil; end

  # Retrieve tracker label from either class or instance.
  Label = ''
  def self.label; self::Label; end
  def label; self.class.label; end

  def configured?
    api_token.present?
  end

  def problem_url(problem)
    "http://#{Errbit::Config.host}/apps/#{problem.app.id}/problems/#{problem.id}"
  end
end

if Rails.env.development?
  Dir[Rails.root.join("app/models/notification_services/*.rb")].each { |file| require_dependency file }
end
