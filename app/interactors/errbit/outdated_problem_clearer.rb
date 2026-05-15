# frozen_string_literal: true

module Errbit
  class OutdatedProblemClearer
    ##
    # Clear all problems whose last_notice_at is older than the configured
    # deprecation window.
    #
    def execute
      nb_problem_outdated.tap do |nb|
        if nb > 0
          criteria.each do |problem|
            Errbit::ProblemDestroy.new(problem).execute
          end
        end
      end
    end

    private

    def nb_problem_outdated
      @count ||= criteria.count
    end

    def criteria
      @criteria ||= Errbit::Problem.where("last_notice_at < ?", Errbit::Config.notice_deprecation_days.to_f.days.ago)
    end
  end
end
