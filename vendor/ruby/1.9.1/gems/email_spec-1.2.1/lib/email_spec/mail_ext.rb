module EmailSpec::MailExt
  def default_part
    @default_part ||= html_part || text_part || self
  end

  def default_part_body
    default_part.body
  end
end

Mail::Message.send(:include, EmailSpec::MailExt)
