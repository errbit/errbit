class IssueTracker
  include Mongoid::Document
  include Mongoid::Timestamps
  include HashHelper
  include Rails.application.routes.url_helpers
  default_url_options[:host] = Errbit::Application.config.action_mailer.default_url_options[:host]

  validate :check_params
  
  embedded_in :app, :inverse_of => :issue_tracker

  field :account, :type => String
  field :api_token, :type => String
  field :project_id, :type => String
  field :issue_tracker_type, :type => String, :default => 'lighthouseapp'

  def create_issue err
    return create_lighthouseapp_issue err if issue_tracker_type == 'lighthouseapp'
    create_redmine_issue err if issue_tracker_type == 'redmine'
  end

  protected
  def create_redmine_issue err
    token = api_token
    acc = account
    RedmineClient::Base.configure do
      self.token = token
      self.site = acc
    end
    issue = RedmineClient::Issue.new(:project_id => project_id)
    issue.subject = issue_title err
    issue.description = self.class.redmine_body_template.result(binding)
    issue.save!
    err.update_attribute :issue_link, "#{RedmineClient::Issue.site.to_s.sub(/#{RedmineClient::Issue.site.path}$/, '')}#{RedmineClient::Issue.element_path(issue.id, :project_id => project_id)}".sub(/\.xml\?project_id=#{project_id}$/, "\?project_id=#{project_id}")
  end

  def create_lighthouseapp_issue err
    Lighthouse.account = account
    Lighthouse.token = api_token

    # updating lighthouse account
    Lighthouse::Ticket.site

    ticket = Lighthouse::Ticket.new(:project_id => project_id)
    ticket.title = issue_title err

    ticket.body = self.class.lighthouseapp_body_template.result(binding)

    ticket.tags << "errbit"
    ticket.save!
    err.update_attribute :issue_link, "#{Lighthouse::Ticket.site.to_s.sub(/#{Lighthouse::Ticket.site.path}$/, '')}#{Lighthouse::Ticket.element_path(ticket.id, :project_id => project_id)}".sub(/\.xml$/, '')
  end

  def issue_title err
    "[#{ err.environment }][#{ err.where }] #{err.message.to_s.truncate(100)}"
  end

  def check_params
    blank_flags = %w( api_token project_id account ).map {|m| self[m].blank? }
    if blank_flags.any? && !blank_flags.all?
      message = if issue_tracker_type == 'lighthouseapp'
        "You must specify your Lighthouseapp account, api token and project id"
      else
        "You must specify your Redmine url, api token and project id"
      end
      errors.add(:base, message)
    end
  end

  class << self
    def lighthouseapp_body_template
      @@lighthouseapp_body_template ||= ERB.new(File.read(Rails.root + "app/views/errs/lighthouseapp_body.txt.erb").gsub(/^\s*/, ''))
    end
  
    def redmine_body_template
      @@redmine_body_template ||= ERB.new(File.read(Rails.root + "app/views/errs/redmine_body.txt.erb").gsub(/^\s*/, ''))
    end
  end
end
