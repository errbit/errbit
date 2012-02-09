require 'heroku/pg_resolver'

module PgUtils
  include PGResolver

  def deprecate_dash_dash_db(name)
    return unless args.include? "--db"
    output_with_bang "The --db option has been deprecated"
    usage = Heroku::Command::Help.usage_for_command(name)
    error "#{usage}"
  end

  def spinner(ticks)
    %w(/ - \\ |)[ticks % 4]
  end

  def ticking
    ticks = 0
    loop do
      yield(ticks)
      ticks +=1
      sleep 1
    end
  end

  def display_info(label, info)
    display(format("%-12s %s", label, info))
  end

  def translate_fork_and_follow(addon, config)
    %w[fork follow].each do |opt|
      if val = config[opt]
        resolved = Resolver.new(val, config_vars)
        display resolved.message if resolved.message
        abort_with_database_list(val) unless resolved[:url]
        config[opt] = resolved[:url]
      end
    end
  end
end
