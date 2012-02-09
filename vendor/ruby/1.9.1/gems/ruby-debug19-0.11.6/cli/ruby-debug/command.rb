require 'rubygems'
require 'columnize'
require_relative 'helper'

module Debugger
  RUBY_DEBUG_DIR = File.expand_path(File.dirname(__FILE__)) unless
    defined?(RUBY_DEBUG_DIR)

  class Command # :nodoc:
    SubcmdStruct=Struct.new(:name, :min, :short_help, :long_help) unless
      defined?(SubcmdStruct)

    include Columnize

    # Find param in subcmds. param id downcased and can be abbreviated
    # to the minimum length listed in the subcommands
    def find(subcmds, param)
      param.downcase!
      for try_subcmd in subcmds do
        if (param.size >= try_subcmd.min) and
            (try_subcmd.name[0..param.size-1] == param)
          return try_subcmd
        end
      end
      return nil
    end

    class << self
      def commands
        @commands ||= []
      end
      
      DEF_OPTIONS = {
        :allow_in_control     => false, 
        :allow_in_post_mortem => true,
        :event => true, 
        :always_run => 0,
        :unknown => false,
        :need_context => false,
      } unless defined?(DEF_OPTIONS)
      
      def inherited(klass)
        DEF_OPTIONS.each do |o, v|
          klass.options[o] = v if klass.options[o].nil?
        end
        commands << klass
      end 

      def load_commands
        Dir[File.join(Debugger.const_get(:RUBY_DEBUG_DIR), 'commands', '*')].each do |file|
          require file if file =~ /\.rb$/
        end
        Debugger.constants.grep(/Functions$/).map { |name| Debugger.const_get(name) }.each do |mod|
          include mod
        end
      end
      
      def method_missing(meth, *args, &block)
        if meth.to_s =~ /^(.+?)=$/
          @options[$1.intern] = args.first
        else
          if @options.has_key?(meth)
            @options[meth]
          else
            super
          end
        end
      end
      
      def options
        @options ||= {}
      end

      def settings_map
        @@settings_map ||= {}
      end
      private :settings_map
      
      def settings
        unless true and defined? @settings and @settings
          @settings = Object.new
          map = settings_map
          c = class << @settings; self end
          if c.respond_to?(:funcall)
            c.funcall(:define_method, :[]) do |name|
              raise "No such setting #{name}" unless map.has_key?(name)
              map[name][:getter].call
            end
          else
            c.send(:define_method, :[]) do |name|
              raise "No such setting #{name}" unless map.has_key?(name)
              map[name][:getter].call
            end
          end
          c = class << @settings; self end
          if c.respond_to?(:funcall)
            c.funcall(:define_method, :[]=) do |name, value|
              raise "No such setting #{name}" unless map.has_key?(name)
              map[name][:setter].call(value)
            end
          else
            c.send(:define_method, :[]=) do |name, value|
              raise "No such setting #{name}" unless map.has_key?(name)
              map[name][:setter].call(value)
            end
          end
        end
        @settings
      end

      def register_setting_var(name, default)
        var_name = "@@#{name}"
        class_variable_set(var_name, default)
        register_setting_get(name) { class_variable_get(var_name) }
        register_setting_set(name) { |value| class_variable_set(var_name, value) }
      end

      def register_setting_get(name, &block)
        settings_map[name] ||= {}
        settings_map[name][:getter] = block
      end

      def register_setting_set(name, &block)
        settings_map[name] ||= {}
        settings_map[name][:setter] = block
      end
    end

    register_setting_var(:basename, false)  # use basename in showing files? 
    register_setting_var(:callstyle, :last)
    register_setting_var(:debuggertesting, false)
    register_setting_var(:force_stepping, false)
    register_setting_var(:full_path, true)
    register_setting_var(:listsize, 10)    # number of lines in list command
    register_setting_var(:stack_trace_on_error, false)
    register_setting_var(:tracing_plus, false) # different linetrace lines?
    
    # width of line output. Use COLUMNS value if it exists and is 
    # not too rediculously large.
    width = ENV['COLUMNS'].to_i 
    width = 80 unless width > 10
    register_setting_var(:width, width)  

    if not defined? Debugger::ARGV
      Debugger::ARGV = ARGV.clone
    end
    register_setting_var(:argv, Debugger::ARGV)
    
    def initialize(state)
      @state = state
    end

    def match(input)
      @match = regexp.match(input)
    end

    protected

    # FIXME: use delegate? 
    def errmsg(*args)
      @state.errmsg(*args)
    end

    def print(*args)
      @state.print(*args)
    end

    def confirm(msg)
      @state.confirm(msg) == 'y'
    end

    def debug_eval(str, b = get_binding)
      begin
        val = eval(str, b)
      rescue StandardError, ScriptError => e
        if Command.settings[:stack_trace_on_error]
          at = eval("caller(1)", b)
          print "%s:%s\n", at.shift, e.to_s.sub(/\(eval\):1:(in `.*?':)?/, '')
          for i in at
            print "\tfrom %s\n", i
          end
        else
          print "#{e.class} Exception: #{e.message}\n"
        end
        throw :debug_error
      end
    end

    def debug_silent_eval(str)
      begin
        eval(str, get_binding)
      rescue StandardError, ScriptError
        nil
      end
    end

    def get_binding
      @state.context.frame_binding(@state.frame_pos)
    end

    def line_at(file, line)
      Debugger.line_at(file, line)
    end

    def get_context(thnum)
      Debugger.contexts.find{|c| c.thnum == thnum}
    end  
  end
  
  Command.load_commands

  # Returns setting object.
  # Use Debugger.settings[] and Debugger.settings[]= methods to query and set
  # debugger settings. These settings are available:
  # 
  # - :autolist - automatically calls 'list' command on breakpoint
  # - :autoeval - evaluates input in the current binding if it's not recognized as a debugger command
  # - :autoirb - automatically calls 'irb' command on breakpoint
  # - :stack_trace_on_error - shows full stack trace if eval command results with an exception
  # - :frame_full_path - displays full paths when showing frame stack
  # - :frame_class_names - displays method's class name when showing frame stack
  # - :reload_source_on_change - makes 'list' command to always display up-to-date source code
  # - :force_stepping - stepping command asways move to the new line
  # 
  def self.settings
    Command.settings
  end
end
