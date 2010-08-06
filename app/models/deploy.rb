class Deploy
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :username
  field :repository
  field :environment
  field :revision
  
  embedded_in :project, :inverse_of => :deploys
  
  after_create :deliver_notification, :if => :should_notify?
  after_create :resolve_project_errs, :if => :should_resolve_project_errs?
  
  validates_presence_of :username, :environment
  
  def deliver_notification
    Mailer.deploy_notification(self).deliver
  end
  
  def resolve_project_errs
    project.errs.unresolved.each {|err| err.resolve!}
  end
  
  protected
  
    def should_notify?
      project.watchers.any?
    end
    
    def should_resolve_project_errs?
      project.resolve_errs_on_deploy?
    end
  
end
