require "heroku"
require "heroku/command"

class Heroku::CLI

  def self.start(*args)
    command = args.shift.strip rescue "help"
    Heroku::Command.load
    Heroku::Command.run(command, args)
  end

end
