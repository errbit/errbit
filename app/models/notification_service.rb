class NotificationService
  include Mongoid::Document

  include Rails.application.routes.url_helpers
  default_url_options[:host] = ActionMailer::Base.default_url_options[:host]
  default_url_options[:port] = ActionMailer::Base.default_url_options[:port]

  field :room_id, :type => String
  field :user_id, :type => String
  field :service_url, :type => String
  field :service, :type => String
  field :api_token, :type => String
  field :subdomain, :type => String
  field :sender_name, :type => String
  field :notify_at_notices, :type => Array, :default => Errbit::Config.notify_at_notices
  embedded_in :app, :inverse_of => :notification_service

  validate :check_params



  if Errbit::Config.per_app_notify_at_notices
    Fields = [[:notify_at_notices,
               { :placeholder => 'comma separated numbers or simply 0 for every notice',
                 :label => 'notify on errors (0 for all errors)'
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

  # Allows us to set the issue tracker class from a single form.
  def type; self._type; end
  def type=(t); self._type=t; end

  def url; nil; end

  # Retrieve tracker label from either class or instance.
  Label = ''
  def self.label; self::Label; end
  def label; self.class.label; end

  def configured?
    api_token.present?
  end

  private

  # Each subclass should call form_* in order to call the correct
  # method for the object.  If you do need to override a certain
  # message simply add the deploy_ or problem_ method to the subclass
  # i.e problem_message deploy_message.  Having said this as each
  # subclass has a custom method for the problem message formation
  # I have left it out of this class.
  def method_missing(method, *args, &block)
    if method.to_s.start_with?('form')
      method = method.to_s.split('_').last
      send_message_type(method, *args)
    else
      super
    end
  end

  def send_message_type(method, message_info)
    meth = "#{message_info.class.name.underscore}_#{method}".to_sym
    send(meth, message_info)
  end

  def deploy_message(deploy)
    %Q(#{deploy_subject(deploy)} with revision #{deploy.revision})
  end
  alias_method :deploy_description, :deploy_message

  def deploy_subject(deploy)
    %Q(#{deploy.app.name} has been deployed to #{deploy.environment})
  end

  def deploy_url(deploy)
    app_url(deploy.app)
  end

  def problem_url(problem)
    app_problem_url(problem.app, problem)
  end

  def problem_description(problem)
    "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s.truncate(100)}"
  end
end
