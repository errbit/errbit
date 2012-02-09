# based on the Rails Plugin

module Heroku
  class Plugin
    include Heroku::Helpers
    extend Heroku::Helpers

    DEPRECATED_PLUGINS = %w(
      heroku-cedar
      heroku-releases
      heroku-postgresql
      heroku-shared-postgresql
      heroku-pgdumps
      heroku-kill
      heroku-logging
      heroku-status
      heroku-stop
      heroku-suggest
      pgbackups-automate
      pgcmd
    )

    attr_reader :name, :uri

    def self.directory
      File.expand_path("#{home_directory}/.heroku/plugins")
    end

    def self.list
      Dir["#{directory}/*"].sort.map do |folder|
        File.basename(folder)
      end
    end

    def self.load!
      list.each do |plugin|
        begin
          check_for_deprecation(plugin)
          next if skip_plugins.include?(plugin)
          load_plugin(plugin)
        rescue ScriptError, StandardError => e
          display "ERROR: Unable to load plugin #{plugin}: #{e.message}"
          display
        end
      end
    end

    def self.load_plugin(plugin)
      folder = "#{self.directory}/#{plugin}"
      $: << "#{folder}/lib"    if File.directory? "#{folder}/lib"
      load "#{folder}/init.rb" if File.exists?  "#{folder}/init.rb"
    end

    def self.remove_plugin(plugin)
      FileUtils.rm_rf("#{self.directory}/#{plugin}")
    end

    def self.check_for_deprecation(plugin)
      return unless STDIN.tty?

      if DEPRECATED_PLUGINS.include?(plugin)
        if confirm "The plugin #{plugin} has been deprecated. Would you like to remove it? (y/N)"
          remove_plugin(plugin)
        end
      end
    end

    def self.skip_plugins
      @skip_plugins ||= ENV["SKIP_PLUGINS"].to_s.split(/ ,/)
    end

    def initialize(uri)
      @uri = uri
      guess_name(uri)
    end

    def to_s
      name
    end

    def path
      "#{self.class.directory}/#{name}"
    end

    def install
      FileUtils.mkdir_p(path)
      Dir.chdir(path) do
        git("init -q")
        git("pull #{uri} master -q")
        unless $?.success?
          FileUtils.rm_rf path
          return false
        end
      end
      true
    end

    def uninstall
      FileUtils.rm_r path if File.directory?(path)
    end

    private
      def guess_name(url)
        @name = File.basename(url)
        @name = File.basename(File.dirname(url)) if @name.empty?
        @name.gsub!(/\.git$/, '') if @name =~ /\.git$/
      end
  end
end
