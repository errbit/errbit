require 'uri'
require 'email_spec/deliveries'

module EmailSpec

  module Helpers
    include Deliveries

    def visit_in_email(link_text)
      visit(parse_email_for_link(current_email, link_text))
    end

    def click_email_link_matching(regex, email = current_email)
      url = links_in_email(email).detect { |link| link =~ regex }
      raise "No link found matching #{regex.inspect} in #{email.default_part_body}" unless url
      visit request_uri(url)
    end

    def click_first_link_in_email(email = current_email)
      link = links_in_email(email).first
      visit request_uri(link)
    end

    def open_email(address, opts={})
      set_current_email(find_email!(address, opts))
    end

    alias_method :open_email_for, :open_email

    def open_last_email
      set_current_email(last_email_sent)
    end

    def open_last_email_for(address)
      set_current_email(mailbox_for(address).last)
    end

    def current_email(address=nil)
      address = convert_address(address)
      email = address ? email_spec_hash[:current_emails][address] : email_spec_hash[:current_email]
      raise   RSpec::Expectations::ExpectationNotMetError, "Expected an open email but none was found. Did you forget to call open_email?" unless email
      email
    end

    def current_email_attachments(address=nil)
      current_email(address).attachments || Array.new
    end

    def unread_emails_for(address)
      mailbox_for(address) - read_emails_for(address)
    end

    def read_emails_for(address)
      email_spec_hash[:read_emails][convert_address(address)] ||= []
    end

    # Should be able to accept String or Regexp options.
    def find_email(address, opts={})
      address = convert_address(address)
      if opts[:with_subject]
        expected_subject = (opts[:with_subject].is_a?(String) ? Regexp.escape(opts[:with_subject]) : opts[:with_subject])
        mailbox_for(address).find { |m| m.subject =~ Regexp.new(expected_subject) }
      elsif opts[:with_text]
        expected_text = (opts[:with_text].is_a?(String) ? Regexp.escape(opts[:with_text]) : opts[:with_text])
        mailbox_for(address).find { |m| m.default_part_body =~ Regexp.new(expected_text) }
      else
        mailbox_for(address).first
      end
    end

    def links_in_email(email)
      URI.extract(email.default_part_body.to_s, ['http', 'https'])
    end

    private

    def email_spec_hash
      @email_spec_hash ||= {:read_emails => {}, :unread_emails => {}, :current_emails => {}, :current_email => nil}
    end

    def find_email!(address, opts={})
      email = find_email(address, opts)
      if email.nil?
        error = "#{opts.keys.first.to_s.humanize unless opts.empty?} #{('"' + opts.values.first.to_s.humanize + '"') unless opts.empty?}"
        raise   RSpec::Expectations::ExpectationNotMetError, "Could not find email #{error}. \n Found the following emails:\n\n #{all_emails.to_s}"
       end
      email
    end

    def set_current_email(email)
      return unless email
      [email.to, email.cc, email.bcc].compact.flatten.each do |to|
        read_emails_for(to) << email
        email_spec_hash[:current_emails][to] = email
      end
      email_spec_hash[:current_email] = email
    end

    def parse_email_for_link(email, text_or_regex)
      email.should have_body_text(text_or_regex)

      url = parse_email_for_explicit_link(email, text_or_regex)
      url ||= parse_email_for_anchor_text_link(email, text_or_regex)

      raise "No link found matching #{text_or_regex.inspect} in #{email}" unless url
      url
    end

    def request_uri(link)
      return unless link
      url = URI::parse(link)
      url.fragment ? (url.request_uri + "#" + url.fragment) : url.request_uri
    end

    # e.g. confirm in http://confirm
    def parse_email_for_explicit_link(email, regex)
      regex = /#{Regexp.escape(regex)}/ unless regex.is_a?(Regexp)
      url = links_in_email(email).detect { |link| link =~ regex }
      request_uri(url)
    end

    # e.g. Click here in  <a href="http://confirm">Click here</a>
    def parse_email_for_anchor_text_link(email, link_text)
      if textify_images(email.default_part_body) =~ %r{<a[^>]*href=['"]?([^'"]*)['"]?[^>]*?>[^<]*?#{link_text}[^<]*?</a>}
        URI.split($1)[5..-1].compact!.join("?").gsub("&amp;", "&")
        # sub correct ampersand after rails switches it (http://dev.rubyonrails.org/ticket/4002)
      else
        return nil
      end
    end

    def textify_images(email_body)
      email_body.to_s.gsub(%r{<img[^>]*alt=['"]?([^'"]*)['"]?[^>]*?/>}) { $1 }
    end

    def parse_email_count(amount)
      case amount
      when "no"
        0
      when "an"
        1
      else
        amount.to_i
      end
    end

    attr_reader :last_email_address

    def convert_address(address)
      @last_email_address = (address || current_email_address)
      AddressConverter.instance.convert(@last_email_address)
    end

    # Overwrite this method to set default email address, for example:
    # last_email_address || @current_user.email
    def current_email_address
      last_email_address
    end


    def mailbox_for(address)
      super(convert_address(address)) # super resides in Deliveries
    end

    def email_spec_deprecate(text)
      puts ""
      puts "DEPRECATION: #{text.split.join(' ')}"
      puts ""
    end

  end
end

