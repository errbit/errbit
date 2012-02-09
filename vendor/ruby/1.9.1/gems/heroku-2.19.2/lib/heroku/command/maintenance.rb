require "heroku/command/base"

module Heroku::Command

  # toggle maintenance mode
  class Maintenance < Base

    # maintenance:on
    #
    # put the app into maintenance mode
    #
    def on
      heroku.maintenance(app, :on)
      display "Maintenance mode enabled."
    end

    # maintenance:off
    #
    # take the app out of maintenance mode
    #
    def off
      heroku.maintenance(app, :off)
      display "Maintenance mode disabled."
    end
  end
end
