class Err
  include Mongoid::Document
  include Mongoid::Timestamps

  field :klass
  field :component
  field :action
  field :environment
  field :fingerprint
  field :last_notice_at, :type => DateTime
  field :resolved, :type => Boolean, :default => false
  field :issue_link, :type => String
  field :notices_count, :type => Integer, :default => 0
  field :message

  index :last_notice_at
  index :app_id
  index :notices

  belongs_to :app
  has_many :notices
  has_many :comments, :inverse_of => :err, :dependent => :destroy

  validates_presence_of :klass, :environment

  scope :resolved, where(:resolved => true)
  scope :unresolved, where(:resolved => false)
  scope :ordered, order_by(:last_notice_at.desc)
  scope :for_apps, lambda {|apps| where(:app_id.in => apps.all.map(&:id))}

  def self.in_env(env)
    env.present? ? where(:environment => env) : scoped
  end

  def self.for(attrs)
    app = attrs.delete(:app)
    app.errs.where(attrs).first || app.errs.create!(attrs)
  end

  def resolve!
    self.update_attributes!(:resolved => true)
  end

  def unresolved?
    !resolved?
  end

  def where
    where = component.dup
    where << "##{action}" if action.present?
    where
  end

  def message
    super || klass
  end

end

