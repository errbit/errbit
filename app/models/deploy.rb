class Deploy
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :username
  field :repository
  field :environment
  field :revision
  
  embedded_in :project, :inverse_of => :deploys
  
  after_create :deliver_notification, :if => :should_notify?
  
  validates_presence_of :username, :environment
  
  def deliver_notification
    Mailer.deploy_notification(self).deliver
  end
  
  protected
  
    def should_notify?
      project.watchers.any?
    end
  
end
