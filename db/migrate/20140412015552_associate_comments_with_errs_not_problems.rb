class AssociateCommentsWithErrsNotProblems < ActiveRecord::Migration
  def up
    add_column :comments, :err_id, :integer
    add_index :comments, :err_id

    Comment.find_each do |comment|
      err_id = Problem.find(comment.problem_id).errs.first.id
      comment.update_column :err_id, err_id
    end
  end

  def down
    remove_column :comments, :err_id
  end
end
