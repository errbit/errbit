class UserMailer < ActionMailer::Base
  default :from => "admin@example.com",
          :sent_on => Time.now.to_s
  
  
  def signup(email, name)
    @name = name
    
    mail :to => email,
         :subject => "Account confirmation"
  end

  def newsletter(email, name)
    @name = name
    
    mail :to => email,
         :subject => "Newsletter sent"
  end

  def attachments_mail(email, name)
    @name = name
    
    add_attachment 'image.png'
    add_attachment 'document.pdf'
    
    mail :to => email,
         :subject => "Attachments test"
  end

  private

  def add_attachment(attachment_name)
    attachment_path = "#{Rails.root}/attachments/#{attachment_name}"
    File.open(attachment_path) do |file|
      filename = File.basename(file.path)
      attachments[filename] = {:content_type => File.mime_type?(file), :content => file.read}
    end
  end
end
