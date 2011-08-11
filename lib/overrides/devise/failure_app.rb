Devise::FailureApp.class_eval do
  protected
    # Handles both 'email_invalid' and 'username_invalid' messages.
    def i18n_message(default = nil)
      message = warden.message || warden_options[:message] || default || :unauthenticated

      if message.is_a?(Symbol)
        I18n.t(:"#{scope}.#{Devise.authentication_keys.first}_#{message}", :resource_name => scope,
               :scope => "devise.failure", :default => [message, message.to_s])
      else
        message.to_s
      end
    end
end

