#
# module for ActionMailer to inline css in html emails
#
module InlineCss
  def render(*args)
    if (template = args.first[:template]) && template.mime_type.html?
      premailer = Premailer.new(super,
                                  :with_html_string => true,
                                  :css => [Rails.root.join("public/stylesheets/email.css").to_s])
      premailer.to_inline_css
    else
      super
    end
  end
end

ActionMailer::Base.send :include, InlineCss

