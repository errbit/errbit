module Debugger  
  class Interface # :nodoc:
    attr_writer :have_readline  # true if Readline is available

    def initialize
      @have_readline = false
    end

    # Common routine for reporting debugger error messages.
    # Derived classed may want to override this to capture output.
    def errmsg(*args)
      if Debugger.annotate.to_i > 2
        aprint 'error-begin'
        print(*args)
        aprint ''
      else
        print '*** '
        print(*args)
      end
    end
    
    # Format msg with gdb-style annotation header
    def afmt(msg, newline="\n")
      "\032\032#{msg}#{newline}"
    end

    def aprint(msg)
      print afmt(msg)
    end

  end

  class LocalInterface < Interface # :nodoc:
    attr_accessor :command_queue
    attr_accessor :histfile
    attr_accessor :history_save
    attr_accessor :history_length
    attr_accessor :restart_file

    unless defined?(FILE_HISTORY)
      FILE_HISTORY = ".rdebug_hist"
    end
    def initialize()
      super
      @command_queue = []
      @have_readline = false
      @history_save = true
      # take gdb's default
      @history_length = ENV["HISTSIZE"] ? ENV["HISTSIZE"].to_i : 256  
      @histfile = File.join(ENV["HOME"]||ENV["HOMEPATH"]||".", 
                            FILE_HISTORY)
      open(@histfile, 'r') do |file|
        file.each do |line|
          line.chomp!
          Readline::HISTORY << line
        end
      end if File.exist?(@histfile)
      @restart_file = nil
    end

    def read_command(prompt)
      readline(prompt, true)
    end
    
    def confirm(prompt)
      readline(prompt, false)
    end
    
    def print(*args)
      STDOUT.printf(*args)
    end
    
    def close
    end

    # Things to do before quitting
    def finalize
      if Debugger.method_defined?("annotate") and Debugger.annotate.to_i > 2
        print "\032\032exited\n\n" 
      end
      if Debugger.respond_to?(:save_history)
        Debugger.save_history 
      end
    end
    
    def readline_support?
      @have_readline
    end

    private
    begin
      require 'readline'
      class << Debugger
        @have_readline = true
        define_method(:save_history) do
          iface = self.handler.interface
          iface.histfile ||= File.join(ENV["HOME"]||ENV["HOMEPATH"]||".", 
                                  FILE_HISTORY)
          open(iface.histfile, 'w') do |file|
            Readline::HISTORY.to_a.last(iface.history_length).each do |line|
              file.puts line unless line.strip.empty?
            end if defined?(iface.history_save) and iface.history_save
          end rescue nil
        end
        public :save_history 
      end
      Debugger.debug_at_exit do 
        finalize if respond_to?(:finalize)
      end
      
      def readline(prompt, hist)
        Readline::readline(prompt, hist)
      end
    rescue LoadError
      def readline(prompt, hist)
        @histfile = ''
        @hist_save = false
        STDOUT.print prompt
        STDOUT.flush
        line = STDIN.gets
        exit unless line
        line.chomp!
        line
      end
    end
  end

  class RemoteInterface < Interface # :nodoc:
    attr_accessor :command_queue
    attr_accessor :histfile
    attr_accessor :history_save
    attr_accessor :history_length
    attr_accessor :restart_file

    def initialize(socket)
      @command_queue = []
      @socket = socket
      @history_save = false
      @history_length = 256
      @histfile = ''
      # Do we read the histfile?
#       open(@histfile, 'r') do |file|
#         file.each do |line|
#           line.chomp!
#           Readline::HISTORY << line
#         end
#       end if File.exist?(@histfile)
      @restart_file = nil
    end
    
    def close
      @socket.close
    rescue Exception
    end
    
    def confirm(prompt)
      send_command "CONFIRM #{prompt}"
    end

    def finalize
    end
    
    def read_command(prompt)
      send_command "PROMPT #{prompt}"
    end
    
    def readline_support?
      false
    end

    def print(*args)
      @socket.printf(*args)
    end
    
    private
    
    def send_command(msg)
      @socket.puts msg
      result = @socket.gets
      raise IOError unless result
      result.chomp
    end
  end
  
  class ScriptInterface < Interface # :nodoc:
    attr_accessor :command_queue
    attr_accessor :histfile
    attr_accessor :history_save
    attr_accessor :history_length
    attr_accessor :restart_file
    def initialize(file, out, verbose=false)
      super()
      @command_queue = []
      @file = file.respond_to?(:gets) ? file : open(file)
      @out = out
      @verbose = verbose
      @history_save = false
      @history_length = 256  # take gdb default
      @histfile = ''
    end
    
    def finalize
    end
    
    def read_command(prompt)
      while result = @file.gets
        puts "# #{result}" if @verbose
        next if result =~ /^\s*#/
        next if result.strip.empty?
        break
      end
      raise IOError unless result
      result.chomp!
    end
    
    def readline_support?
      false
    end

    def confirm(prompt)
      'y'
    end
    
    def print(*args)
      @out.printf(*args)
    end
    
    def close
      @file.close
    end
  end
end
