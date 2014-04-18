class AddLastNoticeCommitAndFirstNoticeCommitToProblems < ActiveRecord::Migration
  def up
    add_column :problems, :first_notice_commit, :string
    add_column :problems, :last_notice_commit, :string
    
    Problem.find_each do |problem|
      ProblemUpdaterCache.new(problem).update
    end
  end
  
  def down
    remove_column :problems, :first_notice_commit
    remove_column :problems, :last_notice_commit
  end
end
