require "heroku/command/base"

module Heroku::Command

  # manage the stack for an app
  class Stack < Base

    # stack
    #
    # show the list of available stacks
    #
    # --all  # include deprecated stacks
    #
    def index
      include_deprecated = true if extract_option("--all")

      list = heroku.list_stacks(app, :include_deprecated => include_deprecated)
      lines = list.map do |stack|
        row = [stack['current'] ? '*' : ' ', stack['name']]
        row << '(beta)' if stack['beta']
        row << '(prepared, will migrate on next git push)' if stack['requested']
        row.join(' ')
      end
      display lines.join("\n")
    end

    # stack:migrate STACK
    #
    # prepare migration of this app to a new stack
    #
    def migrate
      stack = args.shift.downcase.strip rescue nil
      error "No target stack specified." unless stack
      display heroku.migrate_to_stack(app, stack)
    end
  end
end
