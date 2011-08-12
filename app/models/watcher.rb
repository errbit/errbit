class Watcher
  include Mongoid::Document
  include Mongoid::Timestamps

  field :email

  embedded_in :app, :inverse_of => :watchers
  belongs_to :user

  validate :ensure_user_or_email

  before_validation :clear_unused_watcher_type

  attr_accessor :watcher_type

  def watcher_type
    @watcher_type ||= email.present? ? 'email' : 'user'
  end

  def label
    user ? user.name : email
  end

  def address
    user.try(:email) || email
  end

  protected

    def ensure_user_or_email
      errors.add(:base, "You must specify either a user or an email address") unless user.present? || email.present?
    end

    def clear_unused_watcher_type
      case watcher_type
      when 'user'
        self.email = nil
      when 'email'
        self.user = self.user_id = nil
      end
    end

end
