class Comment
  include Mongoid::Document
  include Mongoid::Timestamps

  after_create :increase_counter_cache
  before_destroy :decrease_counter_cache

  field :body, :type => String
  index :user_id

  belongs_to :err, :class_name => "Problem"
  belongs_to :user

  validates_presence_of :body

  protected
    def increase_counter_cache
      err.inc(:comments_count, 1)
    end

    def decrease_counter_cache
      err.inc(:comments_count, -1) if err
    end

end

