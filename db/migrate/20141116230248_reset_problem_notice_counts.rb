class ResetProblemNoticeCounts < ActiveRecord::Migration
  def up
    require "progressbar"
    pbar = ProgressBar.new("problems", Problem.count)
    Problem.find_each do |problem|
      problem.update_column(:notices_count, problem.notices.count)
      pbar.inc
    end
    pbar.finish
  end

  def down
  end
end
