require "heroku/command/base"

module Heroku::Command

  # manage heroku account options
  #
  class Account < Base

    # account:confirm_billing
    #
    # Confirm that your account can be billed at the end of the month
    #
    def confirm_billing
      display(" This action will cause your account to be billed at the end of the month")
      display(" For more information, see http://docs.heroku.com/billing")
      display(" Are you sure you want to do this? (y/n) ", false)
      if ask.downcase == 'y'
        heroku.confirm_billing
        return true
      end
    end
  end
end
