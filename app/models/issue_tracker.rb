class IssueTracker
  include Mongoid::Document
  include Mongoid::Timestamps
  include HashHelper
  include Rails.application.routes.url_helpers
  default_url_options[:host] = Errbit::Application.config.action_mailer.default_url_options[:host]

  validate :check_lighthouseapp_params
  
  embedded_in :app, :inverse_of => :issue_tracker

  field :account, :type => String
  field :api_token, :type => String
  field :project_id, :type => String
  field :issue_tracker_type, :type => String, :default => 'lighthouseapp'

  def create_issue err
    Lighthouse.account = account
    Lighthouse.token = api_token

    # updating lighthouse account
    Lighthouse::Ticket.site

    ticket = Lighthouse::Ticket.new(:project_id => project_id)
    ticket.title = "[#{ err.environment }][#{ err.where }] #{err.message.to_s.truncate(100)}"

    ticket.body = ""
    ticket.body += "[See this exception on Errbit](#{ app_err_url err.app, err } \"See this exception on Errbit\")"
    ticket.body += "\n"
    if notice = err.notices.first
      ticket.body += "# #{notice.message} #"
      ticket.body += "\n"
      ticket.body += "## Summary ##"
      ticket.body += "\n"
      if notice.request['url'].present?
        ticket.body += "### URL ###"
        ticket.body += "\n"
        ticket.body += "[#{notice.request['url']}](#{notice.request['url']})"
        ticket.body += "\n"
      end
      ticket.body += "### Where ###"
      ticket.body += "\n"
      ticket.body += notice.err.where
      ticket.body += "\n"

      ticket.body += "### Occured ###"
      ticket.body += "\n"
      ticket.body += notice.created_at.to_s(:micro)
      ticket.body += "\n"

      ticket.body += "### Similar ###"
      ticket.body += "\n"
      ticket.body += (notice.err.notices.count - 1).to_s
      ticket.body += "\n"

      ticket.body += "## Params ##"
      ticket.body += "\n"
      ticket.body += "<code>#{pretty_hash(notice.params)}</code>"
      ticket.body += "\n"

      ticket.body += "## Session ##"
      ticket.body += "\n"
      ticket.body += "<code>#{pretty_hash(notice.session)}</code>"
      ticket.body += "\n"

      ticket.body += "## Backtrace ##"
      ticket.body += "\n"
      ticket.body += "<code>"
      for line in notice.backtrace
        ticket.body += "#{line['number']}:  #{line['file'].sub(/^\[PROJECT_ROOT\]/, '')} -> **#{line['method']}**"
        ticket.body += "\n"
      end
      ticket.body += "</code>"
      ticket.body += "\n"

      ticket.body += "## Environment ##"
      ticket.body += "\n"
      for key, val in notice.env_vars
        ticket.body += "#{key}: #{val}"
      end
      ticket.body += "\n"
    end

    ticket.tags << "errbit"
    ticket.save!
    err.update_attribute :issue_link, "#{Lighthouse::Ticket.site.to_s.sub(/#{Lighthouse::Ticket.site.path}$/, '')}#{Lighthouse::Ticket.element_path(ticket.id, :project_id => project_id)}".sub(/\.xml$/, '')
  end

  protected
  def check_lighthouseapp_params
    blank_flags = %w( api_token project_id account ).map {|m| self[m].blank? }
    if blank_flags.any? && !blank_flags.all?
      errors.add(:base, "You must specify your Lighthouseapp account, token and project id")
    end
  end
end
