require "heroku"
require "heroku/client"
require "heroku/helpers"

class Heroku::Auth
  class << self
    attr_accessor :credentials

    def client
      @client ||= begin
        client = Heroku::Client.new(user, password, host)
        client.on_warning { |msg| self.display("\n#{msg}\n\n") }
        client
      end
    end

    def login
      delete_credentials
      get_credentials
    end

    def logout
      delete_credentials
    end

    def clear
      @credentials = nil
      @client = nil
    end

    include Heroku::Helpers

    # just a stub; will raise if not authenticated
    def check
      client.list
    end

    def default_host
      "heroku.com"
    end

    def host
      ENV['HEROKU_HOST'] || default_host
    end

    def reauthorize
      @credentials = ask_for_and_save_credentials
    end

    def user    # :nodoc:
      get_credentials
      @credentials[0]
    end

    def password    # :nodoc:
      get_credentials
      @credentials[1]
    end

    def credentials_file
      if host == default_host
        "#{home_directory}/.heroku/credentials"
      else
        "#{home_directory}/.heroku/credentials.#{CGI.escape(host)}"
      end
    end

    def get_credentials    # :nodoc:
      return if @credentials
      unless @credentials = read_credentials
        ask_for_and_save_credentials
      end
      @credentials
    end

    def read_credentials
      File.exists?(credentials_file) and File.read(credentials_file).split("\n")
    end

    def echo_off
      with_tty do
        system "stty -echo"
      end
    end

    def echo_on
      with_tty do
        system "stty echo"
      end
    end

    def ask_for_credentials
      puts "Enter your Heroku credentials."

      print "Email: "
      user = ask

      print "Password: "
      password = running_on_windows? ? ask_for_password_on_windows : ask_for_password
      api_key = Heroku::Client.auth(user, password, host)['api_key']

      [user, api_key]
    end

    def ask_for_password_on_windows
      require "Win32API"
      char = nil
      password = ''

      while char = Win32API.new("crtdll", "_getch", [ ], "L").Call do
        break if char == 10 || char == 13 # received carriage return or newline
        if char == 127 || char == 8 # backspace and delete
          password.slice!(-1, 1)
        else
          # windows might throw a -1 at us so make sure to handle RangeError
          (password << char.chr) rescue RangeError
        end
      end
      puts
      return password
    end

    def ask_for_password
      echo_off
      trap("INT") do
        echo_on
        exit
      end
      password = ask
      puts
      echo_on
      return password
    end

    def ask_for_and_save_credentials
      begin
        @credentials = ask_for_credentials
        write_credentials
        check
      rescue ::RestClient::Unauthorized, ::RestClient::ResourceNotFound => e
        delete_credentials
        clear
        display "Authentication failed."
        retry if retry_login?
        exit 1
      rescue Exception => e
        delete_credentials
        raise e
      end
      check_for_associated_ssh_key unless Heroku::Command.current_command == "keys:add"
    end

    def check_for_associated_ssh_key
      return unless client.keys.length.zero?
      associate_or_generate_ssh_key
    end

    def associate_or_generate_ssh_key
      public_keys = available_ssh_public_keys.sort

      case public_keys.length
      when 0 then
        display "Could not find an existing public key."
        display "Would you like to generate one? [Yn] ", false
        unless ask.strip.downcase == "n"
          display "Generating new SSH public key."
          generate_ssh_key("id_rsa")
          associate_key("#{home_directory}/.ssh/id_rsa.pub")
        end
      when 1 then
        display "Found existing public key: #{public_keys.first}"
        associate_key(public_keys.first)
      else
        display "Found the following SSH public keys:"
        public_keys.each_with_index do |key, index|
          display "#{index+1}) #{File.basename(key)}"
        end
        display "Which would you like to use with your Heroku account? ", false
        chosen = public_keys[ask.to_i-1] rescue error("Invalid choice")
        associate_key(chosen)
      end
    end

    def generate_ssh_key(keyfile)
      ssh_dir = File.join(home_directory, ".ssh")
      unless File.exists?(ssh_dir)
        FileUtils.mkdir_p ssh_dir
        File.chmod(0700, ssh_dir)
      end
      `ssh-keygen -t rsa -N "" -f \"#{home_directory}/.ssh/#{keyfile}\" 2>&1`
    end

    def associate_key(key)
      display "Uploading ssh public key #{key}"
      client.add_key(File.read(key))
    end

    def available_ssh_public_keys
      keys = [
        "#{home_directory}/.ssh/id_rsa.pub",
        "#{home_directory}/.ssh/id_dsa.pub"
      ]
      keys.concat(Dir["#{home_directory}/.ssh/*.pub"])
      keys.select { |d| File.exists?(d) }.uniq
    end

    def retry_login?
      @login_attempts ||= 0
      @login_attempts += 1
      @login_attempts < 3
    end

    def write_credentials
      FileUtils.mkdir_p(File.dirname(credentials_file))
      f = File.open(credentials_file, 'w')
      f.puts self.credentials
      f.close
      set_credentials_permissions
    end

    def set_credentials_permissions
      FileUtils.chmod 0700, File.dirname(credentials_file)
      FileUtils.chmod 0600, credentials_file
    end

    def delete_credentials
      FileUtils.rm_f(credentials_file)
      clear
    end
  end
end
