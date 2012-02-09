require "heroku/command/base"

module Heroku::Command

  # manage app config vars
  #
  class Config < Base

    # config
    #
    # display the config vars for an app
    #
    # -s, --shell  # output config vars in shell format
    #
    def index
      shell = options[:shell]
      vars  = heroku.config_vars(app)
      display_vars(vars, :long => true, :shell => shell)
    end

    # config:add KEY1=VALUE1 ...
    #
    # add one or more config vars
    #
    def add
      unless args.size > 0 and args.all? { |a| a.include?('=') }
        raise CommandFailed, "Usage: heroku config:add <key>=<value> [<key2>=<value2> ...]"
      end

      vars = args.inject({}) do |vars, arg|
        key, value = arg.split('=', 2)
        vars[key] = value
        vars
      end

      # try to get the app to fail fast
      detected_app = app

      display "Adding config vars and restarting app...", false
      heroku.add_config_vars(detected_app, vars)
      display " done", false

      begin
        release = heroku.releases(detected_app).last
        display(", #{release["name"]}", false) if release
      rescue RestClient::RequestFailed => e
      end

      display
      display_vars(vars, :indent => 2)
    end

    alias_command "config:set", "config:add"

    # config:remove KEY1 [KEY2 ...]
    #
    # remove a config var
    #
    def remove
      raise CommandFailed, "Usage: heroku config:remove KEY1 [KEY2 ...]" if args.empty?

      args.each do |key|
        display "Removing #{key} and restarting app...", false
        heroku.remove_config_var(app, key)

        display " done", false
        begin
          release = heroku.releases(app).last
          display(", #{release["name"]}", false) if release
        rescue RestClient::RequestFailed => e
        end
        display ".\n"
      end
    end

    protected
      def display_vars(vars, options={})
        max_length = vars.map { |v| v[0].to_s.size }.max
        vars.keys.sort.each do |key|
          if options[:shell]
            display "#{key}=#{vars[key]}"
          else
            spaces = ' ' * (max_length - key.to_s.size)
            display "#{' ' * (options[:indent] || 0)}#{key}#{spaces} => #{format(vars[key], options)}"
          end
        end
      end

      def format(value, options)
        return value if options[:long] || value.to_s.size < 36
        value[0, 16] + '...' + value[-16, 16]
      end
  end
end
