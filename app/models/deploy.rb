class Deploy
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :username
  field :repository
  field :environment
  field :revision
  field :message

  index :created_at, Mongo::DESCENDING
  
  embedded_in :app, :inverse_of => :deploys
  
  after_create :deliver_notification, :if => :should_notify?
  after_create :resolve_app_errs, :if => :should_resolve_app_errs?
  
  validates_presence_of :username, :environment
  
  def deliver_notification
    Mailer.deploy_notification(self).deliver
  end
  
  def resolve_app_errs
    app.errs.unresolved.in_env(environment).each {|err| err.resolve!}
  end
  
  protected
  
    def should_notify?
      app.notify_on_deploys? && app.watchers.any?
    end
    
    def should_resolve_app_errs?
      app.resolve_errs_on_deploy?
    end
  
end
