module Debugger

  # Implements debugger "jump" command
  class JumpCommand < Command
    self.allow_in_control = true

    def numeric?(object)
      true if Float(object) rescue false
    end

    def regexp
      / ^\s*
         j(?:ump)? \s*
         (?:\s+(\S+))?\s*
         (?:\s+(\S+))?\s*
         $
      /ix
    end

    def execute
      if !@match[1]
        errmsg "\"jump\" must be followed by a line number\n"
        return
      end
      if !numeric?(@match[1])
        puts "Bad line number: " + @match[1]
        return
      end
      line = @match[1].to_i
      line = @state.context.frame_line(0) + line if @match[1][0] == '+' or @match[1][0] == '-'
      if line == @state.context.frame_line(0)
        CommandProcessor.print_location_and_text(@state.context.frame_file(0), line)
        return
      end
      file = @match[2]
      file = @state.context.frame_file(file.to_i) if numeric?(file)
      file = @state.context.frame_file(0) if !file
      case Debugger.current_context.jump(line, file)
      when 0
        @state.proceed
      when 1
        errmsg "Not possible to jump from here\n"
      when 2
        errmsg "Couldn't find debugged frame\n"
      when 3
        errmsg "Couldn't find active code at " + file + ":" + line.to_s + "\n"
      end
    end

    class << self
      def help_command
        %w[jump]
      end

      def help(cmd)
        %{
          j[ump] line\tjump to line number (absolute)
          j[ump] -line\tjump back to line (relative)
          j[ump] +line\tjump ahead to line (relative)

          Change the next line of code to be executed.
         }
     end
    end
  end
end
