#
# Always inline CSS for HTML emails
#
module ActionMailer
  class InlineCssHook
    def self.delivering_email(message)
      if html_part = (message.html_part || (message.content_type =~ /text\/html/ && message))
        premailer = ::Premailer.new(html_part.body.to_s, :with_html_string => true)
        existing_text_part = message.text_part && message.text_part.body.to_s
        # Reset the body
        message.body = nil
        # Add an HTML part with CSS inlined.
        message.html_part do
          content_type "text/html; charset=utf-8"
          body premailer.to_inline_css
        end
        # Add a text part with either the pre-existing text part, or one generated with premailer.
        message.text_part do
          content_type "text/plain; charset=utf-8"
          body existing_text_part || premailer.to_plain_text
        end
      end
    end
  end
end

