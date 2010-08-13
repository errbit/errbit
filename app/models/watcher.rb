class Watcher
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :email
  
  embedded_in :app, :inverse_of => :watchers
  referenced_in :user
  
  validate :ensure_user_or_email
  
  protected
  
    def ensure_user_or_email
      errors.add(:base, "You must specify either a user or an email address") unless user.present? || email.present?
    end
  
end
