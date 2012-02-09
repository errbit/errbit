require 'rails/generators'

class HoptoadGenerator < Rails::Generators::Base

  class_option :api_key, :aliases => "-k", :type => :string, :desc => "Your Hoptoad API key"
  class_option :heroku, :type => :boolean, :desc => "Use the Heroku addon to provide your Hoptoad API key"

  def self.source_root
    @_hoptoad_source_root ||= File.expand_path("../../../../../generators/hoptoad/templates", __FILE__)
  end

  def install
    ensure_api_key_was_configured
    ensure_plugin_is_not_present
    append_capistrano_hook
    generate_initializer unless api_key_configured?
    determine_api_key if heroku?
    test_hoptoad
  end

  private

  def ensure_api_key_was_configured
    if !options[:api_key] && !options[:heroku] && !api_key_configured?
      puts "Must pass --api-key or --heroku or create config/initializers/hoptoad.rb"
      exit
    end
  end

  def ensure_plugin_is_not_present
    if plugin_is_present?
      puts "You must first remove the hoptoad_notifier plugin. Please run: script/plugin remove hoptoad_notifier"
      exit
    end
  end

  def append_capistrano_hook
    if File.exists?('config/deploy.rb') && File.exists?('Capfile')
      append_file('config/deploy.rb', <<-HOOK)

        require './config/boot'
        require 'hoptoad_notifier/capistrano'
      HOOK
    end
  end

  def api_key_expression
    s = if options[:api_key]
      "'#{options[:api_key]}'"
    elsif options[:heroku]
      "ENV['HOPTOAD_API_KEY']"
    end
  end

  def generate_initializer
    template 'initializer.rb', 'config/initializers/hoptoad.rb'
  end

  def determine_api_key
    puts "Attempting to determine your API Key from Heroku..."
    ENV['HOPTOAD_API_KEY'] = heroku_api_key
    if ENV['HOPTOAD_API_KEY'].blank?
      puts "... Failed."
      puts "WARNING: We were unable to detect the Hoptoad API Key from your Heroku environment."
      puts "Your Heroku application environment may not be configured correctly."
      exit 1
    else
      puts "... Done."
      puts "Heroku's Hoptoad API Key is '#{ENV['HOPTOAD_API_KEY']}'"
    end
  end

  def heroku_api_key
    `heroku console 'puts ENV[%{HOPTOAD_API_KEY}]'`.split("\n").first
  end

  def heroku?
    options[:heroku] ||
      system("grep HOPTOAD_API_KEY config/initializers/hoptoad.rb") ||
      system("grep HOPTOAD_API_KEY config/environment.rb")
  end

  def api_key_configured?
    File.exists?('config/initializers/hoptoad.rb')
  end

  def test_hoptoad
    puts run("rake hoptoad:test --trace")
  end

  def plugin_is_present?
    File.exists?('vendor/plugins/hoptoad_notifier')
  end
end
