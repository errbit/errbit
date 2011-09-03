#
# module for ActionMailer to inline css in html emails
#
module InlineCss
  def render(*args)
    if (template = args.first[:template]) && template.mime_type.html?
      # TamTam expects a <style> tag in the head of your layout.
      TamTam.inline(:document => super)
    else
      super
    end
  end
end

