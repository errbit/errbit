require "heroku/command/help"

Heroku::Command::Help.group("Foo Group") do |foo|
  foo.command "foo:bar", "do a bar to foo"
  foo.space
  foo.command "foo:baz", "do a baz to foo"
end

class Heroku::Command::Foo < Heroku::Command::Base
  def bar
  end

  def baz
  end
end

