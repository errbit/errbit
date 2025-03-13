class WatcherDecorator < Draper::Decorator
  delegate_all

  def email_choosen
    object.email.blank? ? "chosen" : ""
  end
end
