require "spec_helper"
require "heroku/command/auth"

module Heroku::Command
  describe Auth do
    before(:each) do
      @cli = prepare_command(Auth)
    end
  end
end
