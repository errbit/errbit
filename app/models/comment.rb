class Comment
  include Mongoid::Document
  include Mongoid::Timestamps

  after_create :increase_counter_cache
  before_destroy :decrease_counter_cache

  after_create :deliver_email, :if => :emailable?

  field :body, :type => String
  index(:user_id => 1)

  belongs_to :err, :class_name => "Problem"
  belongs_to :user
  delegate   :app, :to => :err

  validates_presence_of :body

  def deliver_email
    Mailer.comment_notification(self).deliver
  end

  def notification_recipients
    app.notification_recipients - [user.email]
  end

  def emailable?
    app.emailable? && notification_recipients.any?
  end

  protected
    def increase_counter_cache
      err.inc(:comments_count, 1)
    end

    def decrease_counter_cache
      err.inc(:comments_count, -1) if err
    end

end
