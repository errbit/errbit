require 'irb'

module IRB # :nodoc:
  module ExtendCommand # :nodoc:
    class Continue # :nodoc:
      def self.execute(conf)
        throw :IRB_EXIT, :cont
      end
    end
    class Next # :nodoc:
      def self.execute(conf)
        throw :IRB_EXIT, :next
      end
    end
    class Step # :nodoc:
      def self.execute(conf)
        throw :IRB_EXIT, :step
      end
    end
  end
  ExtendCommandBundle.def_extend_command "cont", :Continue
  ExtendCommandBundle.def_extend_command "n", :Next
  ExtendCommandBundle.def_extend_command "step", :Step
  
  def self.start_session(binding)
    unless @__initialized
      args = ARGV.dup
      ARGV.replace([])
      IRB.setup(nil)
      ARGV.replace(args)
      @__initialized = true
    end
    
    workspace = WorkSpace.new(binding)

    irb = Irb.new(workspace)

    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context

    catch(:IRB_EXIT) do
      irb.eval_input
    end
  end
end

module Debugger

  # Implements debugger "irb" command.
  class IRBCommand < Command

    register_setting_get(:autoirb) do 
      IRBCommand.always_run
    end
    register_setting_set(:autoirb) do |value|
      IRBCommand.always_run = value
    end

    def regexp
      /^\s* irb
        (?:\s+(-d))?
        \s*$/x
    end
    
    def execute
      unless @state.interface.kind_of?(LocalInterface)
        print "Command is available only in local mode.\n"
        throw :debug_error
      end

      save_trap = trap("SIGINT") do
        throw :IRB_EXIT, :cont if $rdebug_in_irb
      end

      add_debugging = @match.is_a?(Array) && '-d' == @match[1]
      $rdebug_state = @state if add_debugging
      $rdebug_in_irb = true
      cont = IRB.start_session(get_binding)
      case cont
      when :cont
        @state.proceed 
      when :step
        force = Command.settings[:force_stepping]
        @state.context.step(1, force)
        @state.proceed 
      when :next
        force = Command.settings[:force_stepping]
        @state.context.step_over(1, @state.frame_pos, force)
        @state.proceed 
      else
        file = @state.context.frame_file(0)
        line = @state.context.frame_line(0)
        CommandProcessor.print_location_and_text(file, line)
        @state.previous_line = nil
      end

    ensure
      $rdebug_in_irb = nil
      $rdebug_state = nil if add_debugging
      trap("SIGINT", save_trap) if save_trap
    end
    
    class << self
      def help_command
        'irb'
      end

      def help(cmd)
        %{
          irb [-d]\tstarts an Interactive Ruby (IRB) session.

If -d is added you can get access to debugger state via the global variable
$RDEBUG_state. 

irb is extended with methods "cont", "n" and "step" which 
run the corresponding debugger commands. In contrast to the real debugger
commands these commands don't allow command arguments.
        }
      end
    end
  end
end

