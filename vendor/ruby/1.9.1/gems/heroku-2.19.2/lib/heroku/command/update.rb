require "heroku/command/base"
require "heroku/updater"

module Heroku::Command

  # update the heroku client
  class Update < Base

    # update
    #
    # update the heroku client
    #
    def index
      if message = Heroku::Updater.disable
        error message
      end

      begin
        output_with_arrow("Updating to latest client... ", false)
        Heroku::Updater.update
        display "done"
      rescue Exception => ex
        display "failed"
        display "   !   #{ex.message}"
      end
    end

    # update:beta
    #
    # update to the latest beta client
    #
    def beta
      output_with_arrow("Updating to latest beta client... ", false)
      Heroku::Updater.update(true)
      display "done"
    rescue Exception => ex
      display "failed"
      display "   !   #{ex.message}"
    end
  end
end
