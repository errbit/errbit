$stdin = File.new("/dev/null")

require "rubygems"
require "bundler/setup"

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "heroku/cli"
require "rspec"
require "rr"
require "fakefs/safe"
require 'tmpdir'
require "webmock/rspec"

include WebMock::API

def stub_api_request(method, path)
  stub_request(method, "https://api.heroku.com#{path}")
end

def prepare_command(klass)
  command = klass.new
  command.stub!(:app).and_return("myapp")
  command.stub!(:ask).and_return("")
  command.stub!(:display)
  command.stub!(:hputs)
  command.stub!(:hprint)
  command.stub!(:heroku).and_return(mock('heroku client', :host => 'heroku.com'))
  command
end

def execute(command_line)
  extend RR::Adapters::RRMethods

  args = command_line.split(" ")
  command = args.shift

  Heroku::Command.load
  object, method = Heroku::Command.prepare_run(command, args)

  $command_output = ""

  def object.print(line=nil)
    $command_output << "#{line}"
  end

  def object.puts(line=nil)
    print("#{line}\n")
  end

  def object.error(line=nil)
    puts(line)
  end

  any_instance_of(Heroku::Command::Base) do |base|
    stub(base).app.returns("myapp")
  end

  object.send(method)
end

def output
  $command_output.gsub(/\n$/, '')
end

def any_instance_of(klass, &block)
  extend RR::Adapters::RRMethods
  any_instance_of(klass, &block)
end

def run(command_line)
  capture_stdout { Heroku::CLI.start(*command_line.split(" ")) }
end

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  fake.string
end

def fail_command(message)
  raise_error(Heroku::Command::CommandFailed, message)
end

def stub_core
  stubbed_core = nil
  any_instance_of(Heroku::Client) do |core|
    stubbed_core = stub(core)
  end
  stub(Heroku::Auth).user.returns("user")
  stub(Heroku::Auth).password.returns("pass")
  stub(Heroku::Client).auth.returns("apikey01")
  stubbed_core
end

def with_blank_git_repository(&block)
  sandbox = File.join(Dir.tmpdir, "heroku", Process.pid.to_s)
  FileUtils.mkdir_p(sandbox)

  old_dir = Dir.pwd
  Dir.chdir(sandbox)

  bash "git init"
  block.call

  FileUtils.rm_rf(sandbox)
ensure
  Dir.chdir(old_dir)
end

module SandboxHelper
  def bash(cmd)
    `#{cmd}`
  end
end

class String
  def undent
    indent = self.match(/^( *)/)[1].length
    self.split("\n").map { |l| l[indent..-1] }.join("\n")
  end
end

require "heroku/helpers"
module Heroku::Helpers
  @home_directory = Dir.mktmpdir
  undef_method :home_directory
  def home_directory
    @home_directory
  end
end

require "support/display_message_matcher"

RSpec.configure do |config|
  config.color_enabled = true
  config.include DisplayMessageMatcher
  config.order = 'rand'
  config.after { RR.reset }
end

