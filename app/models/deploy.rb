class Deploy
  include Mongoid::Document
  include Mongoid::Timestamps

  field :username
  field :repository
  field :environment
  field :revision
  field :message

  index(:created_at => -1)

  embedded_in :app, :inverse_of => :deploys

  after_create :resolve_app_errs, :if => :should_resolve_app_errs?
  after_create :store_cached_attributes_on_problems
  after_create :deliver_email

  validates_presence_of :username, :environment

  def resolve_app_errs
    app.problems.unresolved.in_env(environment).each {|problem| problem.resolve!}
  end

  def short_revision
    revision.to_s[0,7]
  end

  protected

    def should_resolve_app_errs?
      app.resolve_errs_on_deploy?
    end

    def store_cached_attributes_on_problems
      Problem.where(:app_id => app.id).each(&:cache_app_attributes)
    end

    def deliver_email
      if app.notify_on_deploys? && app.notification_recipients.any?
        Mailer.deploy_notification(self).deliver
      end
    end

end

