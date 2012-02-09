require "heroku/command/base"

module Heroku::Command

  # display logs for an app
  #
  class Logs < Base

    # logs
    #
    # display recent log output
    #
    # -n, --num NUM        # the number of lines to display
    # -p, --ps PS          # only display logs from the given process
    # -s, --source SOURCE  # only display logs from the given source
    # -t, --tail           # continually stream logs
    #
    def index
      init_colors

      opts = []
      opts << "tail=1"                                 if options[:tail]
      opts << "num=#{options[:num]}"                   if options[:num]
      opts << "ps=#{URI.encode(options[:ps])}"         if options[:ps]
      opts << "source=#{URI.encode(options[:source])}" if options[:source]

      @line_start = true
      @token = nil

      $stdout.sync = true
      heroku.read_logs(app, opts) do |chk|
        next unless output = format_with_colors(chk)
        puts output
      end
    rescue Errno::EPIPE
    end

    # logs:cron
    #
    # DEPRECATED: display cron logs from legacy logging
    #
    def cron
      display heroku.cron_logs(app)
    end

    # logs:drains
    #
    # DEPRECATED: use `heroku drains`
    #
    def drains
      output_with_bang "The logs:drain command has been deprecated. Please use drains"
      usage = Heroku::Command::Help.usage_for_command("drains")
      puts usage
    end

  protected

    def init_colors(colorizer=nil)
      if !colorizer && STDOUT.isatty && ENV.has_key?("TERM")
        require 'term/ansicolor'
        @colorizer = Term::ANSIColor
      else
        @colorizer = colorizer
      end

      @assigned_colors = {}

      trap("INT") do
        puts @colorizer.reset if @colorizer
        exit
      end
    rescue LoadError
    end

    COLORS = %w( cyan yellow green magenta red )

    def format_with_colors(chunk)
      return if chunk.empty?
      return chunk unless @colorizer

      chunk.split("\n").map do |line|
        header, identifier, body = parse_log(line)
        @assigned_colors[identifier] ||= COLORS[@assigned_colors.size % COLORS.size]
        [
          @colorizer.send(@assigned_colors[identifier]),
          header,
          @colorizer.reset,
          body,
        ].join("")
      end.join("\n")
    end

    def parse_log(log)
      return unless parsed = log.match(/^(.*\[(\w+)([\d\.]+)?\]:)(.*)?$/)
      [1, 2, 4].map { |i| parsed[i] }
    end
  end
end

