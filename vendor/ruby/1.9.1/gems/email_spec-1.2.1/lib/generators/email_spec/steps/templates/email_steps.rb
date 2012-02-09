# Commonly used email steps
#
# To add your own steps make a custom_email_steps.rb
# The provided methods are:
#
# last_email_address
# reset_mailer
# open_last_email
# visit_in_email
# unread_emails_for
# mailbox_for
# current_email
# open_email
# read_emails_for
# find_email
#
# General form for email scenarios are:
#   - clear the email queue (done automatically by email_spec)
#   - execute steps that sends an email
#   - check the user received an/no/[0-9] emails
#   - open the email
#   - inspect the email contents
#   - interact with the email (e.g. click links)
#
# The Cucumber steps below are setup in this order.

module EmailHelpers
  def current_email_address
    # Replace with your a way to find your current email. e.g @current_user.email
    # last_email_address will return the last email address used by email spec to find an email.
    # Note that last_email_address will be reset after each Scenario.
    last_email_address || "example@example.com"
  end
end

World(EmailHelpers)

#
# Reset the e-mail queue within a scenario.
# This is done automatically before each scenario.
#

Given /^(?:a clear email queue|no emails have been sent)$/ do
  reset_mailer
end

#
# Check how many emails have been sent/received
#

Then /^(?:I|they|"([^"]*?)") should receive (an|no|\d+) emails?$/ do |address, amount|
  unread_emails_for(address).size.should == parse_email_count(amount)
end

Then /^(?:I|they|"([^"]*?)") should have (an|no|\d+) emails?$/ do |address, amount|
  mailbox_for(address).size.should == parse_email_count(amount)
end

Then /^(?:I|they|"([^"]*?)") should receive (an|no|\d+) emails? with subject "([^"]*?)"$/ do |address, amount, subject|
  unread_emails_for(address).select { |m| m.subject =~ Regexp.new(Regexp.escape(subject)) }.size.should == parse_email_count(amount)
end

Then /^(?:I|they|"([^"]*?)") should receive (an|no|\d+) emails? with subject \/([^"]*?)\/$/ do |address, amount, subject|
  unread_emails_for(address).select { |m| m.subject =~ Regexp.new(subject) }.size.should == parse_email_count(amount)
end

Then /^(?:I|they|"([^"]*?)") should receive an email with the following body:$/ do |address, expected_body|
  open_email(address, :with_text => expected_body)
end

#
# Accessing emails
#

# Opens the most recently received email
When /^(?:I|they|"([^"]*?)") opens? the email$/ do |address|
  open_email(address)
end

When /^(?:I|they|"([^"]*?)") opens? the email with subject "([^"]*?)"$/ do |address, subject|
  open_email(address, :with_subject => subject)
end

When /^(?:I|they|"([^"]*?)") opens? the email with subject \/([^"]*?)\/$/ do |address, subject|
  open_email(address, :with_subject => Regexp.new(subject))
end

When /^(?:I|they|"([^"]*?)") opens? the email with text "([^"]*?)"$/ do |address, text|
  open_email(address, :with_text => text)
end

When /^(?:I|they|"([^"]*?)") opens? the email with text \/([^"]*?)\/$/ do |address, text|
  open_email(address, :with_text => Regexp.new(text))
end

#
# Inspect the Email Contents
#

Then /^(?:I|they) should see "([^"]*?)" in the email subject$/ do |text|
  current_email.should have_subject(text)
end

Then /^(?:I|they) should see \/([^"]*?)\/ in the email subject$/ do |text|
  current_email.should have_subject(Regexp.new(text))
end

Then /^(?:I|they) should see "([^"]*?)" in the email body$/ do |text|
  current_email.default_part_body.to_s.should include(text)
end

Then /^(?:I|they) should see \/([^"]*?)\/ in the email body$/ do |text|
  current_email.default_part_body.to_s.should =~ Regexp.new(text)
end

Then /^(?:I|they) should see the email delivered from "([^"]*?)"$/ do |text|
  current_email.should be_delivered_from(text)
end

Then /^(?:I|they) should see "([^\"]*)" in the email "([^"]*?)" header$/ do |text, name|
  current_email.should have_header(name, text)
end

Then /^(?:I|they) should see \/([^\"]*)\/ in the email "([^"]*?)" header$/ do |text, name|
  current_email.should have_header(name, Regexp.new(text))
end

Then /^I should see it is a multi\-part email$/ do
    current_email.should be_multipart
end

Then /^(?:I|they) should see "([^"]*?)" in the email html part body$/ do |text|
    current_email.html_part.body.to_s.should include(text)
end

Then /^(?:I|they) should see "([^"]*?)" in the email text part body$/ do |text|
    current_email.text_part.body.to_s.should include(text)
end

#
# Inspect the Email Attachments
#

Then /^(?:I|they) should see (an|no|\d+) attachments? with the email$/ do |amount|
  current_email_attachments.size.should == parse_email_count(amount)
end

Then /^there should be (an|no|\d+) attachments? named "([^"]*?)"$/ do |amount, filename|
  current_email_attachments.select { |a| a.filename == filename }.size.should == parse_email_count(amount)
end

Then /^attachment (\d+) should be named "([^"]*?)"$/ do |index, filename|
  current_email_attachments[(index.to_i - 1)].filename.should == filename
end

Then /^there should be (an|no|\d+) attachments? of type "([^"]*?)"$/ do |amount, content_type|
  current_email_attachments.select { |a| a.content_type.include?(content_type) }.size.should == parse_email_count(amount)
end

Then /^attachment (\d+) should be of type "([^"]*?)"$/ do |index, content_type|
  current_email_attachments[(index.to_i - 1)].content_type.should include(content_type)
end

Then /^all attachments should not be blank$/ do
  current_email_attachments.each do |attachment|
    attachment.read.size.should_not == 0
  end
end

Then /^show me a list of email attachments$/ do
  EmailSpec::EmailViewer::save_and_open_email_attachments_list(current_email)
end

#
# Interact with Email Contents
#

When /^(?:I|they) follow "([^"]*?)" in the email$/ do |link|
  visit_in_email(link)
end

When /^(?:I|they) click the first link in the email$/ do
  click_first_link_in_email
end

#
# Debugging
# These only work with Rails and OSx ATM since EmailViewer uses RAILS_ROOT and OSx's 'open' command.
# Patches accepted. ;)
#

Then /^save and open current email$/ do
  EmailSpec::EmailViewer::save_and_open_email(current_email)
end

Then /^save and open all text emails$/ do
  EmailSpec::EmailViewer::save_and_open_all_text_emails
end

Then /^save and open all html emails$/ do
  EmailSpec::EmailViewer::save_and_open_all_html_emails
end

Then /^save and open all raw emails$/ do
  EmailSpec::EmailViewer::save_and_open_all_raw_emails
end
