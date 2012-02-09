require "heroku/command/base"

module Heroku::Command

  # manage ssl certificates for an app
  #
  class Ssl < Base

    # ssl
    #
    # list certificates for an app
    #
    def index
      heroku.list_domains(app).each do |d|
        if cert = d[:cert]
          display "#{d[:domain]} has a SSL certificate registered to #{cert[:subject]} which expires on #{cert[:expires_at].strftime("%b %d, %Y")}"
        else
          display "#{d[:domain]} has no certificate"
        end
      end
    end

    # ssl:add PEM KEY
    #
    # add an ssl certificate to an app
    #
    def add
      pem_file = args.shift
      key_file = args.shift
      fail "Usage: heroku ssl:add PEM KEY" unless pem_file && key_file
      raise CommandFailed, "Missing pem file." unless pem_file
      raise CommandFailed, "Missing key file." unless key_file
      raise CommandFailed, "Could not find pem in #{pem_file}"  unless File.exists?(pem_file)
      raise CommandFailed, "Could not find key in #{key_file}"  unless File.exists?(key_file)

      pem  = File.read(pem_file)
      key  = File.read(key_file)
      info = heroku.add_ssl(app, pem, key)
      display "Added certificate to #{info['domain']}, expiring in #{info['expires_at']}"
    end

    # ssl:remove DOMAIN
    #
    # remove an ssl certificate from an app
    #
    def remove
      raise CommandFailed, "Missing domain. Usage:\nheroku ssl:remove <domain>" unless domain = args.shift
      heroku.remove_ssl(app, domain)
      display "Removed certificate from #{domain}"
    end

    # ssl:clear
    #
    # remove all ssl certificates from an app
    #
    def clear
      heroku.clear_ssl(app)
      display "Cleared certificates for #{app}"
    end
  end
end
