require "heroku/command/base"

module Heroku::Command

  # display syslog drains for an app
  #
  class Drains < Base

    # drains
    #
    # list all syslog drains
    #
    def index
      puts heroku.list_drains(app)
      return
    end

    # drains:add URL
    #
    # add a syslog drain
    #
    def add
      if url = args.shift
        puts heroku.add_drain(app, url)
        return
      else
        raise(CommandFailed, "usage: heroku drains:add URL")
      end
    end

    # drains:remove URL
    #
    # remove a syslog drain
    #
    def remove
      if url = args.shift
        puts heroku.remove_drain(app, url)
        return
      else
        raise(CommandFailed, "usage: heroku drains remove URL")
      end
    end

  end
end

