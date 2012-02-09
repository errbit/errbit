require 'premailer'
require 'nokogiri'
require 'action_mailer/inline_css_hook'
require 'overrides/premailer/premailer'
require 'overrides/premailer/adapter/nokogiri'

ActionMailer::Base.register_interceptor ActionMailer::InlineCssHook

