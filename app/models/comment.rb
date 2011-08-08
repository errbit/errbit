class Comment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :body, :type => String
  index :user_id

  belongs_to :err
  belongs_to :user

  validates_presence_of :body
end

