class NotificationService
  include Mongoid::Document

  field :room_id, :type => String
  field :api_token, :type => String
  field :subdomain, :type => String

  validate :check_params

  # Subclasses are responsible for overwriting this method.
  def check_params; true; end

  def notification_description(problem)
    "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s.truncate(100)}"
  end

  # Allows us to set the issue tracker class from a single form.
  def type; self._type; end
  def type=(t); self._type=t; end

  # Retrieve tracker label from either class or instance.
  Label = ''
  def self.label; self::Label; end
  def label; self.class.label; end
end
