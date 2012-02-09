require "heroku/command/base"

module Heroku::Command

  # manage custom domains
  #
  class Domains < Base

    # domains
    #
    # list custom domains for an app
    #
    def index
      domains = heroku.list_domains(app)
      if domains.empty?
        display "No domain names for #{app_url}"
      else
        display "Domain names for #{app_url}:"
        display domains.map { |d| d[:domain] }.join("\n")
      end
    end

    # domains:add DOMAIN
    #
    # add a custom domain to an app
    #
    def add
      domain = args.shift.downcase rescue nil
      fail("Usage: heroku domains:add DOMAIN") if domain.to_s.strip.empty?
      heroku.add_domain(app, domain)
      display "Added #{domain} as a custom domain name for #{app}"
    end

    # domains:remove DOMAIN
    #
    # remove a custom domain from an app
    #
    def remove
      domain = args.shift.downcase rescue nil
      fail("Usage: heroku domains:remove DOMAIN") if domain.to_s.strip.empty?
      heroku.remove_domain(app, domain)
      display "Removed #{domain} as a custom domain name for #{app}"
    end

    # domains:clear
    #
    # remove all custom domains from an app
    #
    def clear
      heroku.remove_domains(app)
      display "Removed all domain names for #{app}"
    end

    protected
      def app_url
        url = heroku.info(app)[:web_url]
        url.to_s.gsub('http://', '').gsub(/\/$/, '')
      end
  end
end
