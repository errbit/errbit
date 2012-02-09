require "heroku/command/base"

# display version
#
class Heroku::Command::Version < Heroku::Command::Base

  # version
  #
  # show heroku client version
  #
  def index
    display Heroku::Client.gem_version_string
  end

end
