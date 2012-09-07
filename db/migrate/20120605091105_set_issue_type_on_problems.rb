class SetIssueTypeOnProblems < Mongoid::Migration
  def self.up
    Problem.all.each do |p|
      if p.issue_link.present? && p.app.issue_tracker_configured?
        p.update_attribute :issue_type, p.app.issue_tracker.label
      end
    end
  end

  def self.down
  end
end
