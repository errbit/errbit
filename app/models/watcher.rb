# frozen_string_literal: true

class Watcher
  include Mongoid::Document
  include Mongoid::Timestamps

  field :email

  embedded_in :app, inverse_of: :watchers
  belongs_to :user, optional: true

  validate :ensure_user_or_email

  before_validation :clear_unused_watcher_type

  attr_accessor :watcher_type

  def watcher_type
    @watcher_type ||= email.present? ? "email" : "user"
  end

  def label
    user ? user.name : email
  end

  def address
    user&.email || email
  end

  def email_choosen
    email.blank? ? "chosen" : ""
  end

  # For migration from MongoDB to SQL store.
  # TODO: remove after migration
  def attributes_for_migration
    # TODO: check for missing fields
    {
      bson_id: id
    }
  end

  private

  def ensure_user_or_email
    errors.add(:base, "You must specify either a user or an email address") unless user.present? || email.present?
  end

  def clear_unused_watcher_type
    case watcher_type
    when "user"
      self.email = nil
    when "email"
      self.user = nil
      self.user_id = nil
    end
  end
end
