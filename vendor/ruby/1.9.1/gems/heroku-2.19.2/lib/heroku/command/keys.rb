require "heroku/command/base"

module Heroku::Command

  # manage authentication keys
  #
  class Keys < Base

    # keys
    #
    # display keys for the current user
    #
    # -l, --long  # display extended information for each key
    #
    def index
      long = options[:long]
      keys = heroku.keys
      if keys.empty?
        display "No keys for #{heroku.user}"
      else
        display "=== #{keys.size} key#{'s' if keys.size > 1} for #{heroku.user}"
        keys.each do |key|
          display long ? key.strip : format_key_for_display(key)
        end
      end
    end

    # keys:add [KEY]
    #
    # add a key for the current user
    #
    # if no KEY is specified, will try to find ~/.ssh/id_[rd]sa.pub
    #
    def add
      if keyfile = args.first
        display "Uploading ssh public key #{keyfile}"
        heroku.add_key(File.read(keyfile))
      else
        # make sure we have credentials
        Heroku::Auth.get_credentials
        Heroku::Auth.associate_or_generate_ssh_key
      end
    end

    # keys:remove KEY
    #
    # remove a key from the current user
    #
    def remove
      heroku.remove_key(args.first)
      display "Key #{args.first} removed."
    end

    # keys:clear
    #
    # remove all authentication keys from the current user
    #
    def clear
      heroku.remove_all_keys
      display "All keys removed."
    end

    protected
      def format_key_for_display(key)
        type, hex, local = key.strip.split(/\s/)
        [type, hex[0,10] + '...' + hex[-10,10], local].join(' ')
      end
  end
end
