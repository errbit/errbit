class EnsureThatProblemsLastNoticeAtIsNotNil < Mongoid::Migration
  def self.up
    Problem.where("$or" => [{:last_notice_at => nil}, {:first_notice_at => nil}]).each do |problem|
      first_notice = problem.notices.order_by([:created_at, :asc]).first

      # Destroy problems with no notices
      if first_notice.nil?
        problem.destroy
        next
      end

      last_notice = problem.notices.order_by([:created_at, :asc]).last

      problem.update_attributes!({
        :first_notice_at => first_notice.created_at,
        :last_notice_at => last_notice.created_at
      })
    end
  end

  def self.down
  end
end
