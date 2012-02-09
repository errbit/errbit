class WelcomeController < ApplicationController
  def signup
    UserMailer.signup(params['Email'], params['Name']).deliver
  end

  def confirm
  end

  def newsletter
    Delayed::Job.enqueue(NotifierJob.new(:newsletter,params['Email'], params['Name']))
  end

  def attachments
    UserMailer.attachments_mail(params['Email'], params['Name']).deliver
  end
end
