# frozen_string_literal: true

module Errbit
  class ProblemDestroy
    attr_reader :problem

    def initialize(problem)
      @problem = problem
    end

    def execute
      delete_errs
      delete_comments
      problem.delete
    end

    def self.execute(problems)
      Array(problems).each do |problem|
        new(problem).execute
      end.count
    end

    private

    def errs_id
      problem.errs.pluck(:id)
    end

    def comments_id
      problem.comments.pluck(:id)
    end

    def delete_errs
      Errbit::Notice.where(errbit_err_id: errs_id).delete_all
      Errbit::Err.where(id: errs_id).delete_all
    end

    def delete_comments
      Errbit::Comment.where(id: comments_id).delete_all
    end
  end
end
