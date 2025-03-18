# frozen_string_literal: true

class ProblemRecacher
  LOG_EVERY = 100
  LOG_ITR = "%.1f%% complete, %i problem(s) remaining"
  LOG_START = "Re-caching problem attributes for %i problems"

  def self.run
    count = Problem.count
    puts format(LOG_START, count)

    Problem.no_timeout.each_with_index do |problem, index|
      problem.recache
      problem.destroy if problem.notices_count == 0

      next unless (index + 1) % LOG_EVERY == 0
      puts format(LOG_ITR, (index * 100 / count), count - index)
    end

    puts "Finished re-caching problem attributes"
  end

  def self.puts(*args)
    Rails.logger.info(*args)
  end
end
