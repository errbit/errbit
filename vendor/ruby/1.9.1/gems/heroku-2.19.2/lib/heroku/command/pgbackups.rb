require "heroku/command/base"
require "heroku/pg_resolver"
require "heroku/pgutils"
require "pgbackups/client"

module Heroku::Command

  # manage backups of heroku postgresql databases
  class Pgbackups < Base
    include PGResolver
    include PgUtils

    # pgbackups
    #
    # list captured backups
    #
    def index
      backups = []
      pgbackup_client.get_transfers.each { |t|
        next unless backup_types.member?(t['to_name']) && !t['error_at'] && !t['destroyed_at']
        backups << [backup_name(t['to_url']), t['created_at'], t['size'], t['from_name'], ]
      }

      if backups.empty?
        no_backups_error!
      else
        display Display.new.render([["ID", "Backup Time", "Size", "Database"]], backups)
      end
    end

    # pgbackups:url [BACKUP_ID]
    #
    # get a temporary URL for a backup
    #
    def url
      if name = args.shift
        b = pgbackup_client.get_backup(name)
      else
        b = pgbackup_client.get_latest_backup
      end
      abort("No backup found.") unless b['public_url']
      if STDOUT.tty?
        display '"'+b['public_url']+'"'
      else
        display b['public_url']
      end
    end

    # pgbackups:capture [DATABASE]
    #
    # capture a backup from a database id
    #
    # if no DATABASE is specified, defaults to DATABASE_URL
    #
    # -e, --expire  # if no slots are available to capture, destroy the oldest backup to make room
    #
    def capture
      deprecate_dash_dash_db("pgbackups:capture")

      db = resolve_db(:allow_default => true)

      from_url  = db[:url]
      from_name = db[:name]
      to_url    = nil # server will assign
      to_name   = "BACKUP"
      opts      = {:expire => extract_option("--expire")}

      backup = transfer!(from_url, from_name, to_url, to_name, opts)

      to_uri = URI.parse backup["to_url"]
      backup_id = to_uri.path.empty? ? "error" : File.basename(to_uri.path, '.*')
      display "\n#{db[:pretty_name]}  ----backup--->  #{backup_id}"

      backup = poll_transfer!(backup)

      if backup["error_at"]
        message  =   "An error occurred and your backup did not finish."
        message += "\nThe database is not yet online. Please try again." if backup['log'] =~ /Name or service not known/
        message += "\nThe database credentials are incorrect."           if backup['log'] =~ /psql: FATAL:/
        error(message)
      end
    end

    # pgbackups:restore [<DATABASE> [BACKUP_ID|BACKUP_URL]]
    #
    # restore a backup to a database
    #
    # if no DATABASE is specified, defaults to DATABASE_URL and latest backup
    # if DATABASE is specified, but no BACKUP_ID, defaults to latest backup
    #
    def restore
      deprecate_dash_dash_db("pgbackups:restore")

      if 0 == args.size
        db = resolve_db(:allow_default => true)
        backup_id = :latest
      elsif 1 == args.size
        db = resolve_db
        backup_id = :latest
      else
        db = resolve_db
        backup_id = args.shift
      end

      to_name = db[:name]
      to_url  = db[:url]

      if :latest == backup_id
        backup = pgbackup_client.get_latest_backup
        no_backups_error! if {} == backup
        to_uri = URI.parse backup["to_url"]
        backup_id = File.basename(to_uri.path, '.*')
        backup_id = "#{backup_id} (most recent)"
        from_url  = backup["to_url"]
        from_name = "BACKUP"
      elsif backup_id =~ /^http(s?):\/\//
        from_url  = backup_id
        from_name = "EXTERNAL_BACKUP"
        from_uri  = URI.parse backup_id
        backup_id = from_uri.path.empty? ? from_uri : File.basename(from_uri.path)
      else
        backup = pgbackup_client.get_backup(backup_id)
        abort("Backup #{backup_id} already destroyed.") if backup["destroyed_at"]

        from_url  = backup["to_url"]
        from_name = "BACKUP"
      end

      message = "#{db[:pretty_name]}  <---restore---  "
      padding = " " * message.length
      display "\n#{message}#{backup_id}"
      if backup
        display padding + "#{backup['from_name']}"
        display padding + "#{backup['created_at']}"
        display padding + "#{backup['size']}"
      end

      if confirm_command
        restore = transfer!(from_url, from_name, to_url, to_name)
        restore = poll_transfer!(restore)

        if restore["error_at"]
          message  =   "An error occurred and your restore did not finish."
          message += "\nThe backup url is invalid. Use `pgbackups:url` to generate a new temporary URL." if restore['log'] =~ /Invalid dump format: .*: XML  document text/
          error(message)
        end
      end
    end

    # pgbackups:destroy BACKUP_ID
    #
    # destroys a backup
    #
    def destroy
      name = args.shift
      abort("Backup name required") unless name
      backup = pgbackup_client.get_backup(name)
      abort("Backup #{name} already destroyed.") if backup["destroyed_at"]

      result = pgbackup_client.delete_backup(name)
      if result
        display("Backup #{name} destroyed.")
      else
        abort("Error deleting backup #{name}.")
      end
    end

    protected

    def config_vars
      @config_vars ||= heroku.config_vars(app)
    end

    def pgbackup_client
      pgbackups_url = ENV["PGBACKUPS_URL"] || config_vars["PGBACKUPS_URL"]
      error("Please add the pgbackups addon first via:\nheroku addons:add pgbackups") unless pgbackups_url
      @pgbackup_client ||= PGBackups::Client.new(pgbackups_url)
    end

    def backup_name(to_url)
      # translate s3://bucket/email/foo/bar.dump => foo/bar
      parts = to_url.split('/')
      parts.slice(4..-1).join('/').gsub(/\.dump$/, '')
    end

    def transfer!(from_url, from_name, to_url, to_name, opts={})
      pgbackup_client.create_transfer(from_url, from_name, to_url, to_name, opts)
    end

    def poll_transfer!(transfer)
      display "\n"

      if transfer["errors"]
        transfer["errors"].values.flatten.each { |e|
          output_with_bang "#{e}"
        }
        abort
      end

      while true
        update_display(transfer)
        break if transfer["finished_at"]

        sleep 1
        transfer = pgbackup_client.get_transfer(transfer["id"])
      end

      display "\n"

      return transfer
    end

    def update_display(transfer)
      @ticks            ||= 0
      @last_updated_at  ||= 0
      @last_logs        ||= []
      @last_progress    ||= ["", 0]

      @ticks += 1

      step_map = {
        "dump"      => "Capturing",
        "upload"    => "Storing",
        "download"  => "Retrieving",
        "restore"   => "Restoring",
        "gunzip"    => "Uncompressing",
        "load"      => "Restoring",
      }

      if !transfer["log"]
        @last_progress = ['pending', nil]
        redisplay "Pending... #{spinner(@ticks)}"
      else
        logs        = transfer["log"].split("\n")
        new_logs    = logs - @last_logs
        @last_logs  = logs

        new_logs.each do |line|
          matches = line.scan /^([a-z_]+)_progress:\s+([^ ]+)/
          next if matches.empty?

          step, amount = matches[0]

          if ['done', 'error'].include? amount
            # step is done, explicitly print result and newline
            redisplay "#{@last_progress[0].capitalize}... #{amount}\n"
          end

          # store progress, last one in the logs will get displayed
          step = step_map[step] || step
          @last_progress = [step, amount]
        end

        step, amount = @last_progress
        unless ['done', 'error'].include? amount
          redisplay "#{step.capitalize}... #{amount} #{spinner(@ticks)}"
        end
      end
    end

    class Display
      attr_reader :columns, :rows

      def initialize(columns=nil, rows=nil, opts={})
        @columns = columns
        @rows = rows
        @opts = opts.update(:display_columns => @columns, :display_rows => @rows)
      end

      def render(*data)
        _data = data
        data = DataSource.new(data, @opts)

        # join in grid lines
        lines = []
        data.rows.each { |row|
          lines << row.join(@opts[:delimiter] || " | ")
        }

        # insert header grid line
        if _data.length > 1
          grid_row = data.rows.first.map { |datum| "-" * datum.length }
          grid_line = grid_row.join("-+-")
          lines.insert(1, grid_line)
          lines << "" # trailing newline
        end
        return lines.join("\n")
      end

      class DataSource
        attr_reader :rows, :columns

        def initialize(data, opts={})
          rows = []
          data.each { |d| rows += d }
          columns = rows.transpose

          max_widths = columns.map { |c|
            c.map { |datum| datum.length }.max
          }

          max_widths = [10, 10] if opts[:display_columns]

          @columns = []
          columns.each_with_index { |c,i|
            column = @columns[i] = []
            c.each { |d| column << d.ljust(max_widths[i]) }
          }
          @rows = @columns.transpose
        end
      end
    end

    private

    def no_backups_error!
      error("No backups. Capture one with `heroku pgbackups:capture`.")
    end

    # lists all types of backups ('to_name' attribute)
    #
    # Useful when one doesn't care if a backup is of a particular
    # kind, but wants to know what backups of any kind exist.
    #
    def backup_types
      %w[BACKUP DAILY_SCHEDULED_BACKUP HOURLY_SCHEDULED_BACKUP AUTO_SCHEDULED_BACKUP]
    end
  end
end
