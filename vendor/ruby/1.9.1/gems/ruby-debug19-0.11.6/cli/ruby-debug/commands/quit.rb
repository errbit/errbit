module Debugger

  # Implements debugger "quit" command
  class QuitCommand < Command
    self.allow_in_control = true

    def regexp
      / ^\s*
         (?:q(?:uit)?|exit) \s*
         (!|\s+unconditionally)? \s*
         $
      /ix
    end

    def execute
      if @match[1] or confirm("Really quit? (y/n) ") 
        @state.interface.finalize
        exit! # exit -> exit!: No graceful way to stop threads...
      end
    end

    class << self
      def help_command
        %w[quit exit]
      end

      def help(cmd)
        %{
          q[uit] [!|unconditionally]\texit from debugger. 
          exit[!]\talias to quit

          Normally we prompt before exiting. However if the parameter
          "unconditionally" or is given or suffixed with !, we stop
          without asking further questions.  
         }
     end
    end
  end
end
