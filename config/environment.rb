# frozen_string_literal: true

# Load the Rails application.
require_relative "application"

# case Config.errbit.log_location
# when "STDOUT"
#   # Skip. This is rails default behavior
# when "Syslog::Logger"
#   require "syslog/logger"
#
#   Rails.logger = Syslog::Logger.new("errbit", Syslog::LOG_LOCAL0)
# else
#   Rails.logger = ActiveSupport::Logger.new(Config.errbit.log_location)
# end

# Initialize the Rails application.
Rails.application.initialize!
