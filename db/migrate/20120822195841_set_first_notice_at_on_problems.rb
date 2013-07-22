class SetFirstNoticeAtOnProblems < Mongoid::Migration
  def self.up
    Problem.all.each do |problem|
      problem.update_attribute :first_notice_at, problem.notices.order_by([:created_at, :asc]).first.try(:created_at)
    end
  end

  def self.down
  end
end
