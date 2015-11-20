class Deploy
  include Mongoid::Document
  include Mongoid::Timestamps

  field :username
  field :repository
  field :environment
  field :revision
  field :message

  index(created_at: -1)

  embedded_in :app, inverse_of: :deploys

  after_create :resolve_app_errs, if: :should_resolve_app_errs?
  after_create :store_cached_attributes_on_problems
  after_create :deliver_email

  validates :username, :environment, presence: true

  def resolve_app_errs
    app.problems.unresolved.in_env(environment).each(&:resolve!)
  end

  def short_revision
    revision.to_s[0, 7]
  end

protected

  def should_resolve_app_errs?
    app.resolve_errs_on_deploy?
  end

  def store_cached_attributes_on_problems
    Problem.where(app_id: app.id).update_all(
      last_deploy_at: created_at
    )
  end

  def deliver_email
    if app.notify_on_deploys? && app.notification_recipients.any?
      Mailer.deploy_notification(self).deliver_now
    end
  end
end
