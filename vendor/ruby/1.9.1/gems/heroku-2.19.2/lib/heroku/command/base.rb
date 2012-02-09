require "fileutils"
require "heroku/auth"
require "heroku/client/rendezvous"
require "heroku/command"

class Heroku::Command::Base
  include Heroku::Helpers

  def self.namespace
    self.to_s.split("::").last.downcase
  end

  attr_reader :args
  attr_reader :options

  def initialize(args=[], options={})
    @args = args
    @options = options
  end

  def app
    @app ||= if options[:app].is_a?(String)
      if confirm_mismatch?
        raise Heroku::Command::CommandFailed, "Mismatch between --app and --confirm"
      end
      options[:app]
    elsif options[:confirm].is_a?(String)
      options[:confirm]
    elsif app_from_dir = extract_app_in_dir(Dir.pwd)
      app_from_dir
    else
      raise Heroku::Command::CommandFailed, "No app specified.\nRun this command from an app folder or specify which app to use with --app <app name>"
    end
  end


  def heroku
    Heroku::Auth.client
  end

protected

  def self.inherited(klass)
    return if klass == Heroku::Command::Base

    help = extract_help_from_caller(caller.first)

    Heroku::Command.register_namespace(
      :name => klass.namespace,
      :description => help.split("\n").first
    )
  end

  def self.method_added(method)
    return if self == Heroku::Command::Base
    return if private_method_defined?(method)
    return if protected_method_defined?(method)

    help = extract_help_from_caller(caller.first)
    resolved_method = (method.to_s == "index") ? nil : method.to_s
    command = [ self.namespace, resolved_method ].compact.join(":")
    banner = extract_banner(help) || command
    permute = !banner.index("*")
    banner.gsub!("*", "")

    Heroku::Command.register_command(
      :klass       => self,
      :method      => method,
      :namespace   => self.namespace,
      :command     => command,
      :banner      => banner,
      :help        => help,
      :summary     => extract_summary(help),
      :description => extract_description(help),
      :options     => extract_options(help),
      :permute     => permute
    )
  end

  def self.alias_command(new, old)
    raise "no such command: #{old}" unless Heroku::Command.commands[old]
    Heroku::Command.command_aliases[new] = old
  end

  def extract_app
    output_with_bang "Command::Base#extract_app has been deprecated. Please use Command::Base#app instead.  #{caller.first}"
    app
  end

  #
  # Parse the caller format and identify the file and line number as identified
  # in : http://www.ruby-doc.org/core/classes/Kernel.html#M001397.  This will
  # look for a colon followed by a digit as the delimiter.  The biggest
  # complication is windows paths, which have a color after the drive letter.
  # This regex will match paths as anything from the beginning to a colon
  # directly followed by a number (the line number).
  #
  # Examples of the caller format :
  # * c:/Ruby192/lib/.../lib/heroku/command/addons.rb:8:in `<module:Command>'
  # * c:/Ruby192/lib/.../heroku-2.0.1/lib/heroku/command/pg.rb:96:in `<class:Pg>'
  # * /Users/ph7/...../xray-1.1/lib/xray/thread_dump_signal_handler.rb:9
  #
  def self.extract_help_from_caller(line)
    # pull out of the caller the information for the file path and line number
    if line =~ /^(.+?):(\d+)/
      return extract_help($1, $2)
    end
    raise "unable to extract help from caller: #{line}"
  end

  def self.extract_help(file, line)
    buffer = []
    lines  = File.read(file).split("\n")

    catch(:done) do
      (line.to_i-2).downto(0) do |i|
        case lines[i].strip[0..0]
          when "", "#" then buffer << lines[i]
          else throw(:done)
        end
      end
    end

    buffer.map! do |line|
      line.strip.gsub(/^#/, "")
    end

    buffer.reverse.join("\n").strip
  end

  def self.extract_banner(help)
    help.split("\n").first
  end

  def self.extract_summary(help)
    extract_description(help).split("\n").first
  end

  def self.extract_description(help)
    lines = help.split("\n").map { |l| l.strip }
    lines.shift
    lines.reject do |line|
      line =~ /^-(.+)#(.+)/
    end.join("\n").strip
  end

  def self.extract_options(help)
    help.split("\n").map { |l| l.strip }.select do |line|
      line =~ /^-(.+)#(.+)/
    end.inject({}) do |hash, line|
      description = line.split("#", 2).last.strip
      long  = line.match(/--([A-Za-z\- ]+)/)[1].strip
      short = line.match(/-([A-Za-z ])/)[1].strip
      hash.update(long.split(" ").first => { :desc => description, :short => short, :long => long })
    end
  end

  def extract_option(name, default=true)
    key = name.gsub("--", "").to_sym
    return unless options[key]
    value = options[key] || default
    block_given? ? yield(value) : value
  end

  def confirm_mismatch?
    options[:confirm] && (options[:confirm] != options[:app])
  end

  def extract_app_in_dir(dir)
    return unless remotes = git_remotes(dir)

    if remote = options[:remote]
      remotes[remote]
    elsif remote = extract_app_from_git_config
      remotes[remote]
    else
      apps = remotes.values.uniq
      return apps.first if apps.size == 1
    end
  end

  def extract_app_from_git_config
    remote = git("config heroku.remote")
    remote == "" ? nil : remote
  end

  def git_remotes(base_dir=Dir.pwd)
    remotes = {}
    original_dir = Dir.pwd
    Dir.chdir(base_dir)

    git("remote -v").split("\n").each do |remote|
      name, url, method = remote.split(/\s/)
      if url =~ /^git@#{heroku.host}:([\w\d-]+)\.git$/
        remotes[name] = $1
      end
    end

    Dir.chdir(original_dir)
    remotes
  end

  def escape(value)
    heroku.escape(value)
  end
end

module Heroku::Command
  unless const_defined?(:BaseWithApp)
    BaseWithApp = Base
  end
end
