class AddLastNoticeEnvironmentAndFirstNoticeEnvironmentToProblems < ActiveRecord::Migration
  def up
    add_column :problems, :first_notice_environment, :string
    add_column :problems, :last_notice_environment, :string

    Problem.find_each do |problem|
      ProblemUpdaterCache.new(problem).update
    end
  end

  def down
    remove_column :problems, :first_notice_environment
    remove_column :problems, :last_notice_environment
  end
end
