require 'rexml/document'
require 'rest_client'
require 'uri'
require 'time'
require 'heroku/auth'
require 'heroku/helpers'
require 'heroku/version'

# A Ruby class to call the Heroku REST API.  You might use this if you want to
# manage your Heroku apps from within a Ruby program, such as Capistrano.
#
# Example:
#
#   require 'heroku'
#   heroku = Heroku::Client.new('me@example.com', 'mypass')
#   heroku.create('myapp')
#
class Heroku::Client

  include Heroku::Helpers
  extend Heroku::Helpers

  def self.version
    Heroku::VERSION
  end

  def self.gem_version_string
    "heroku-gem/#{version}"
  end

  attr_accessor :host, :user, :password

  def self.auth(user, password, host=Heroku::Auth.default_host)
    client = new(user, password, host)
    json_decode client.post('/login', { :username => user, :password => password }, :accept => 'json').to_s
  end

  def initialize(user, password, host=Heroku::Auth.default_host)
    @user = user
    @password = password
    @host = host
  end

  # Show a list of apps which you are a collaborator on.
  def list
    doc = xml(get('/apps').to_s)
    doc.elements.to_a("//apps/app").map do |a|
      name = a.elements.to_a("name").first
      owner = a.elements.to_a("owner").first
      [name.text, owner.text]
    end
  end

  # Show info such as mode, custom domain, and collaborators on an app.
  def info(name_or_domain)
    raise ArgumentError.new("name_or_domain is required for info") unless name_or_domain
    name_or_domain = name_or_domain.gsub(/^(http:\/\/)?(www\.)?/, '')
    doc = xml(get("/apps/#{name_or_domain}").to_s)
    attrs = hash_from_xml_doc(doc)[:app]
    attrs.merge!(:collaborators => list_collaborators(attrs[:name]))
    attrs.merge!(:addons        => installed_addons(attrs[:name]))
  end

  # Create a new app, with an optional name.
  def create(name=nil, options={})
    name = create_request(name, options)
    loop do
      break if create_complete?(name)
      sleep 1
    end
    name
  end

  def create_request(name=nil, options={})
    options[:name] = name if name
    xml(post('/apps', :app => options).to_s).elements["//app/name"].text
  end

  def create_complete?(name)
    put("/apps/#{name}/status", {}).code == 201
  end

  # Update an app.  Available attributes:
  #   :name => rename the app (changes http and git urls)
  def update(name, attributes)
    put("/apps/#{name}", :app => attributes).to_s
  end

  # Destroy the app permanently.
  def destroy(name)
    delete("/apps/#{name}").to_s
  end

  # Get a list of collaborators on the app, returns an array of hashes each with :email
  def list_collaborators(app_name)
    doc = xml(get("/apps/#{app_name}/collaborators").to_s)
    doc.elements.to_a("//collaborators/collaborator").map do |a|
      { :email => a.elements['email'].text }
    end
  end

  # Invite a person by email address to collaborate on the app.
  def add_collaborator(app_name, email)
    xml(post("/apps/#{app_name}/collaborators", { 'collaborator[email]' => email }).to_s)
  end

  # Remove a collaborator.
  def remove_collaborator(app_name, email)
    delete("/apps/#{app_name}/collaborators/#{escape(email)}").to_s
  end

  def list_domains(app_name)
    doc = xml(get("/apps/#{app_name}/domains").to_s)
    doc.elements.to_a("//domain-names/*").map do |d|
      attrs = { :domain => d.elements['domain'].text }
      if cert = d.elements['cert']
        attrs[:cert] = {
          :expires_at => Time.parse(cert.elements['expires-at'].text),
          :subject    => cert.elements['subject'].text,
          :issuer     => cert.elements['issuer'].text,
        }
      end
      attrs
    end
  end

  def add_domain(app_name, domain)
    post("/apps/#{app_name}/domains", domain).to_s
  end

  def remove_domain(app_name, domain)
    raise ArgumentError.new("invalid domain: #{domain.inspect}") if domain.to_s.strip == ""
    delete("/apps/#{app_name}/domains/#{domain}").to_s
  end

  def remove_domains(app_name)
    delete("/apps/#{app_name}/domains").to_s
  end

  def add_ssl(app_name, pem, key)
    json_decode(post("/apps/#{app_name}/ssl", :pem => pem, :key => key).to_s)
  end

  def remove_ssl(app_name, domain)
    delete("/apps/#{app_name}/domains/#{domain}/ssl").to_s
  end

  def clear_ssl(app_name)
    delete("/apps/#{app_name}/ssl")
  end

  # Get the list of ssh public keys for the current user.
  def keys
    doc = xml get('/user/keys').to_s
    doc.elements.to_a('//keys/key').map do |key|
      key.elements['contents'].text
    end
  end

  # Add an ssh public key to the current user.
  def add_key(key)
    post("/user/keys", key, { 'Content-Type' => 'text/ssh-authkey' }).to_s
  end

  # Remove an existing ssh public key from the current user.
  def remove_key(key)
    delete("/user/keys/#{escape(key)}").to_s
  end

  # Clear all keys on the current user.
  def remove_all_keys
    delete("/user/keys").to_s
  end

  # Get a list of stacks available to the app, with the current one marked.
  def list_stacks(app_name, options={})
    include_deprecated = options.delete(:include_deprecated) || false

    json_decode resource("/apps/#{app_name}/stack").get(
      :params => { :include_deprecated => include_deprecated },
      :accept => 'application/json'
    ).to_s
  end

  # Request a stack migration.
  def migrate_to_stack(app_name, stack)
    resource("/apps/#{app_name}/stack").put(stack, :accept => 'text/plain').to_s
  end

  class AppCrashed < RuntimeError; end

  # Run a rake command on the Heroku app and return all output as
  # a string.
  def rake(app_name, cmd)
    start(app_name, "rake #{cmd}", :attached).to_s
  end

  # support for console sessions
  class ConsoleSession
    def initialize(id, app, client)
      @id = id; @app = app; @client = client
    end
    def run(cmd)
      @client.run_console_command("/apps/#{@app}/consoles/#{@id}/command", cmd, "=> ")
    end
  end

  # Execute a one-off console command, or start a new console tty session if
  # cmd is nil.
  def console(app_name, cmd=nil)
    if block_given?
      id = post("/apps/#{app_name}/consoles").to_s
      yield ConsoleSession.new(id, app_name, self)
      delete("/apps/#{app_name}/consoles/#{id}").to_s
    else
      run_console_command("/apps/#{app_name}/console", cmd)
    end
  rescue RestClient::BadGateway => e
    raise(AppCrashed, <<-ERROR)
Unable to attach to a dyno to open a console session.
Your application may have crashed.
Check the output of "heroku ps" and "heroku logs" for more information.
    ERROR
  end

  # internal method to run console commands formatting the output
  def run_console_command(url, command, prefix=nil)
    output = post(url, { :command => command }, :accept => "text/plain").to_s
    return output unless prefix
    if output.include?("\n")
      lines  = output.split("\n")
      (lines[0..-2] << "#{prefix}#{lines.last}").join("\n")
    else
      prefix + output
    end
  rescue RestClient::RequestFailed => e
    if e.http_code == 422
      Heroku::Command.extract_error(e.http_body, :raw => true)
    else
      raise e
    end
  end

  class Service
    attr_accessor :attached, :upid

    def initialize(client, app, upid=nil)
      @client = client
      @app = app
      @upid = upid
    end

    # start the service
    def start(command, attached=false)
      @attached = attached
      @response = @client.post(
        "/apps/#{@app}/services",
        command,
        :content_type => 'text/plain'
      )
      @next_chunk = @response.to_s
      @interval = 0
      self
    rescue RestClient::RequestFailed => e
      raise AppCrashed, e.http_body  if e.http_code == 502
      raise
    end

    def transition(action)
      @response = @client.put(
        "/apps/#{@app}/services/#{@upid}",
        action,
        :content_type => 'text/plain'
      ).to_s
      self
    rescue RestClient::RequestFailed => e
      raise AppCrashed, e.http_body  if e.http_code == 502
      raise
    end

    def down   ; transition('down') ; end
    def up     ; transition('up')   ; end
    def bounce ; transition('bounce') ; end

    # Does the service have any remaining output?
    def end_of_stream?
      @next_chunk.nil?
    end

    # Read the next chunk of output.
    def read
      chunk = @client.get(@next_chunk)
      if chunk.headers[:location].nil? && chunk.code != 204
        # no more chunks
        @next_chunk = nil
        chunk.to_s
      elsif chunk.to_s == ''
        # assume no content and back off
        @interval = 2
        ''
      elsif location = chunk.headers[:location]
        # some data read and next chunk available
        @next_chunk = location
        @interval = 0
        chunk.to_s
      end
    end

    # Iterate over all output chunks until EOF is reached.
    def each
      until end_of_stream?
        sleep(@interval)
        output = read
        yield output unless output.empty?
      end
    end

    # All output as a string
    def to_s
      buf = []
      each { |part| buf << part }
      buf.join
    end
  end

  # Retreive ps list for the given app name.
  def ps(app_name)
    json_decode resource("/apps/#{app_name}/ps").get(:accept => 'application/json').to_s
  end

  # Run a service. If Responds to #each and yields output as it's received.
  def start(app_name, command, attached=false)
    service = Service.new(self, app_name)
    service.start(command, attached)
  end

  # Get a Service instance to execute commands against.
  def service(app_name, upid)
    Service.new(self, app_name, upid)
  end

  # Bring a service up.
  def up(app_name, upid)
    service(app_name, upid).up
  end

  # Bring a service down.
  def down(app_name, upid)
    service(app_name, upid).down
  end

  # Bounce a service.
  def bounce(app_name, upid)
    service(app_name, upid).bounce
  end


  # Restart the app servers.
  def restart(app_name)
    delete("/apps/#{app_name}/server").to_s
  end

  # Fetch recent logs from the app server.
  def logs(app_name)
    get("/apps/#{app_name}/logs").to_s
  end

  # Fetch recent cron logs from the app server.
  def cron_logs(app_name)
    get("/apps/#{app_name}/cron_logs").to_s
  end

  def read_logs(app_name, options=[])
    query = "&" + options.join("&") unless options.empty?
    url = get("/apps/#{app_name}/logs?logplex=true#{query}").to_s
    if url == 'Use old logs'
      puts get("/apps/#{app_name}/logs").to_s
    else
      uri  = URI.parse(url);

      if uri.scheme == 'https'
        proxy = ENV['HTTPS_PROXY'] || ENV['https_proxy']
      else
        proxy = ENV['HTTP_PROXY'] || ENV['http_proxy']
      end

      if proxy
        unless /^[^:]+:\/\// =~ proxy
          proxy = "http://" + proxy
        end
        proxy = URI.parse(proxy)
        http = Net::HTTP.new(uri.host, uri.port, proxy.host, proxy.port, proxy.user, proxy.password)
      else
        http = Net::HTTP.new(uri.host, uri.port)
      end

      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.read_timeout = 60 * 60 * 24

      begin
        http.start do
          http.request_get(uri.path + (uri.query ? "?" + uri.query : "")) do |request|
            request.read_body do |chunk|
              yield chunk
            end
          end
        end
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError
        error("Could not connect to logging service")
      rescue Timeout::Error, EOFError
        error("\nRequest timed out")
      end
    end
  end

  def list_drains(app_name)
    get("/apps/#{app_name}/logs/drains").to_s
  end

  def add_drain(app_name, url)
    post("/apps/#{app_name}/logs/drains", "url=#{url}").to_s
  end

  def remove_drain(app_name, url)
    delete("/apps/#{app_name}/logs/drains?url=#{URI.escape(url)}").to_s
  end

  def dynos(app_name)
    doc = xml(get("/apps/#{app_name}").to_s)
    doc.elements["//app/dynos"].text.to_i
  end

  def workers(app_name)
    doc = xml(get("/apps/#{app_name}").to_s)
    doc.elements["//app/workers"].text.to_i
  end

  # Scales the web processes.
  def set_dynos(app_name, qty)
    put("/apps/#{app_name}/dynos", :dynos => qty).to_s
  end

  # Scales the background processes.
  def set_workers(app_name, qty)
    put("/apps/#{app_name}/workers", :workers => qty).to_s
  end

  def config_vars(app_name)
    json_decode get("/apps/#{app_name}/config_vars", :accept => :json).to_s
  end

  def add_config_vars(app_name, new_vars)
    put("/apps/#{app_name}/config_vars", json_encode(new_vars), :accept => :json).to_s
  end

  def remove_config_var(app_name, key)
    delete("/apps/#{app_name}/config_vars/#{escape(key)}", :accept => :json).to_s
  end

  def clear_config_vars(app_name)
    delete("/apps/#{app_name}/config_vars").to_s
  end

  def addons
    json_decode get("/addons", :accept => 'application/json').to_s
  end

  def installed_addons(app_name)
    json_decode get("/apps/#{app_name}/addons", :accept => 'application/json').to_s
  end

  def install_addon(app_name, addon, config={})
    configure_addon :install, app_name, addon, config
  end

  def upgrade_addon(app_name, addon, config={})
    configure_addon :upgrade, app_name, addon, config
  end
  alias_method :downgrade_addon, :upgrade_addon

  def uninstall_addon(app_name, addon, options={})
    configure_addon :uninstall, app_name, addon, options
  end

  def database_session(app_name)
    json_decode(post("/apps/#{app_name}/database/session2", '', :x_taps_version => ::Taps.version).to_s)
  end

  def database_reset(app_name)
    post("/apps/#{app_name}/database/reset", '').to_s
  end

  def maintenance(app_name, mode)
    mode = mode == :on ? '1' : '0'
    post("/apps/#{app_name}/server/maintenance", :maintenance_mode => mode).to_s
  end

  def httpcache_purge(app_name)
    delete("/apps/#{app_name}/httpcache").to_s
  end

  def releases(app)
    json_decode get("/apps/#{app}/releases", :accept => :json).to_s
  end

  def release(app, release)
    json_decode get("/apps/#{app}/releases/#{release}", :accept => :json).to_s
  end

  def rollback(app, release=nil)
    post("/apps/#{app}/releases", :rollback => release)
  end

  def ps_run(app, opts={})
    json_decode post("/apps/#{app}/ps", opts, :accept => :json).to_s
  end

  def ps_scale(app, opts={})
    Integer(post("/apps/#{app}/ps/scale", opts).to_s)
  end

  def ps_restart(app, opts={})
    post("/apps/#{app}/ps/restart", opts)
  end

  def ps_stop(app, opts={})
    post("/apps/#{app}/ps/stop", opts)
  end

  def confirm_billing
    post("/user/#{escape(@user)}/confirm_billing").to_s
  end

  def on_warning(&blk)
    @warning_callback = blk
  end

  ##################

  def resource(uri, options={})
    RestClient.proxy = ENV['HTTP_PROXY'] || ENV['http_proxy']
    resource = RestClient::Resource.new(realize_full_uri(uri), options.merge(:user => user, :password => password))
    resource
  end

  def get(uri, extra_headers={})    # :nodoc:
    process(:get, uri, extra_headers)
  end

  def post(uri, payload="", extra_headers={})    # :nodoc:
    process(:post, uri, extra_headers, payload)
  end

  def put(uri, payload, extra_headers={})    # :nodoc:
    process(:put, uri, extra_headers, payload)
  end

  def delete(uri, extra_headers={})    # :nodoc:
    process(:delete, uri, extra_headers)
  end

  def process(method, uri, extra_headers={}, payload=nil)
    headers  = heroku_headers.merge(extra_headers)
    args     = [method, payload, headers].compact

    resource_options = default_resource_options_for_uri(uri)

    begin
      response = resource(uri, resource_options).send(*args)
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError
      host = URI.parse(realize_full_uri(uri)).host
      error "Unable to connect to #{host}"
    rescue RestClient::SSLCertificateNotVerified => ex
      host = URI.parse(realize_full_uri(uri)).host
      error "WARNING: Unable to verify SSL certificate for #{host}\nTo disable SSL verification, run with HEROKU_SSL_VERIFY=disable"
    end

    extract_warning(response)
    response
  end

  def extract_warning(response)
    return unless response
    if response.headers[:x_heroku_warning] && @warning_callback
      warning = response.headers[:x_heroku_warning]
      @displayed_warnings ||= {}
      unless @displayed_warnings[warning]
        @warning_callback.call(warning)
        @displayed_warnings[warning] = true
      end
    end
  end

  def heroku_headers   # :nodoc:
    {
      'X-Heroku-API-Version' => '2',
      'User-Agent'           => self.class.gem_version_string,
      'X-Ruby-Version'       => RUBY_VERSION,
      'X-Ruby-Platform'      => RUBY_PLATFORM
    }
  end

  def xml(raw)   # :nodoc:
    REXML::Document.new(raw)
  end

  def escape(value)  # :nodoc:
    escaped = URI.escape(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    escaped.gsub('.', '%2E') # not covered by the previous URI.escape
  end

  module JSON
    def self.parse(json)
      json_decode(json)
    end
  end

  private

  def configure_addon(action, app_name, addon, config = {})
    response = update_addon action,
                            addon_path(app_name, addon),
                            config

    json_decode(response.to_s) unless response.to_s.empty?
  end

  def addon_path(app_name, addon)
    "/apps/#{app_name}/addons/#{escape(addon)}"
  end

  def update_addon(action, path, config)
    params  = { :config => config }
    app     = params[:config].delete(:confirm)
    headers = { :accept => 'application/json' }
    params.merge!(:confirm => app) if app

    case action
    when :install
      post path, params, headers
    when :upgrade
      put path, params, headers
    when :uninstall
      confirm = app ? "confirm=#{app}" : ''
      delete "#{path}?#{confirm}", headers
    end
  end

  def realize_full_uri(given)
    full_host = (host =~ /^http/) ? host : "https://api.#{host}"
    host = URI.parse(full_host)
    uri = URI.parse(given)
    uri.host ||= host.host
    uri.scheme ||= host.scheme || "https"
    uri.path = (uri.path[0..0] == "/") ? uri.path : "/#{uri.path}"
    uri.port = host.port if full_host =~ /\:\d+/
    uri.to_s
  end

  def default_resource_options_for_uri(uri)
    if ENV["HEROKU_SSL_VERIFY"] == "disable"
      {}
    elsif realize_full_uri(uri) =~ %r|^https://api.heroku.com|
      { :verify_ssl => OpenSSL::SSL::VERIFY_PEER, :ssl_ca_file => local_ca_file }
    else
      {}
    end
  end

  def local_ca_file
    File.expand_path("../../../data/cacert.pem", __FILE__)
  end

  def hash_from_xml_doc(elements)
    elements.inject({}) do |hash, e|
      next(hash) unless e.respond_to?(:children)
      hash.update(e.name.gsub("-","_").to_sym => case e.children.length
        when 0 then nil
        when 1 then e.text
        else hash_from_xml_doc(e.children)
      end)
    end
  end
end
