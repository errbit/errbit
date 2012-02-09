require 'net/http'
require 'uri'
require 'active_support'

# Capistrano tasks for notifying Hoptoad of deploys
module HoptoadTasks

  # Alerts Hoptoad of a deploy.
  #
  # @param [Hash] opts Data about the deploy that is set to Hoptoad
  #
  # @option opts [String] :rails_env Environment of the deploy (production, staging)
  # @option opts [String] :scm_revision The given revision/sha that is being deployed
  # @option opts [String] :scm_repository Address of your repository to help with code lookups
  # @option opts [String] :local_username Who is deploying
  def self.deploy(opts = {})
    if HoptoadNotifier.configuration.api_key.blank?
      puts "I don't seem to be configured with an API key.  Please check your configuration."
      return false
    end

    if opts[:rails_env].blank?
      puts "I don't know to which Rails environment you are deploying (use the TO=production option)."
      return false
    end

    dry_run = opts.delete(:dry_run)
    params = {'api_key' => opts.delete(:api_key) ||
                             HoptoadNotifier.configuration.api_key}
    opts.each {|k,v| params["deploy[#{k}]"] = v }

    url = URI.parse("http://#{HoptoadNotifier.configuration.host || 'hoptoadapp.com'}/deploys.txt")

    proxy = Net::HTTP.Proxy(HoptoadNotifier.configuration.proxy_host,
                            HoptoadNotifier.configuration.proxy_port,
                            HoptoadNotifier.configuration.proxy_user,
                            HoptoadNotifier.configuration.proxy_pass)

    if dry_run
      puts url, params.inspect
      return true
    else
      response = proxy.post_form(url, params)

      puts response.body
      return Net::HTTPSuccess === response
    end
  end
end

