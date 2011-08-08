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
  field :ticket_properties, :type => String
  field :username, :type => String
  field :password, :type => String
  field :issue_tracker_type, :type => String, :default => 'none'

  def create_issue err
    case issue_tracker_type
    when 'lighthouseapp'
      create_lighthouseapp_issue err
    when 'redmine'
      create_redmine_issue err
    when 'pivotal'
      create_pivotal_issue err
    when 'fogbugz'
      create_fogbugz_issue err
    when 'mingle'
      create_mingle_issue err
    end
  end

  def ticket_properties_hash
    # Parses 'key=value, key2=value2' from user input into a ruby hash.
    self.ticket_properties.split(",").inject({}) do |hash, pair|
      key, value = pair.split("=").map(&:strip)
      hash[key] = value
      hash
    end
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

  def create_pivotal_issue err
    PivotalTracker::Client.token = api_token
    PivotalTracker::Client.use_ssl = true
    project = PivotalTracker::Project.find project_id.to_i
    story = project.stories.create :name => issue_title(err), :story_type => 'bug', :description => self.class.pivotal_body_template.result(binding)
    err.update_attribute :issue_link, "https://www.pivotaltracker.com/story/show/#{story.id}"
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

  def create_fogbugz_issue err
    fogbugz = Fogbugz::Interface.new(:email => username, :password => password, :uri => "https://#{account}.fogbugz.com")
    fogbugz.authenticate

    issue = {}
    issue['sTitle'] = issue_title err
    issue['sArea'] = project_id
    issue['sEvent'] = self.class.fogbugz_body_template.result(binding)
    issue['sTags'] = ['errbit'].join(',')
    issue['cols'] = ['ixBug'].join(',')

    fb_resp = fogbugz.command(:new, issue)
    err.update_attribute :issue_link, "https://#{account}.fogbugz.com/default.asp?#{fb_resp['case']['ixBug']}"
  end

  def create_mingle_issue err
    properties = ticket_properties_hash
    basic_auth = account.gsub(/https?:\/\//, "https://#{username}:#{password}@")
    Mingle.set_site "#{basic_auth}/api/v1/projects/#{project_id}/"

    card = Mingle::Card.new
    card.card_type_name = properties.delete("card_type")
    card.name = issue_title(err)
    card.description = self.class.mingle_body_template.result(binding)
    properties.each do |property, value|
      card.send("cp_#{property}=", value)
    end

    card.save!
    err.update_attribute :issue_link, URI.parse("#{account}/projects/#{project_id}/cards/#{card.id}").to_s
  end

  def issue_title err
    "[#{ err.environment }][#{ err.where }] #{err.message.to_s.truncate(100)}"
  end

  def check_params
    blank_flag_fields = %w(project_id)
    if %w(fogbugz mingle).include?(issue_tracker_type)
      blank_flag_fields += %w(username password)
    else
      blank_flag_fields << 'api_token'
    end
    blank_flag_fields << 'account' if(%w(fogbugz lighthouseapp redmine mingle).include?(issue_tracker_type))
    blank_flags = blank_flag_fields.map {|m| self[m].blank? }

    if issue_tracker_type == "mingle"
      # Check that mingle was given a 'card_type' in the ticket_properties
      blank_flags << "card_type" unless ticket_properties_hash["card_type"]
    end

    if blank_flags.any? && !blank_flags.all?
      message = case issue_tracker_type
      when 'lighthouseapp'
        'You must specify your Lighthouseapp account, API token and Project ID'
      when 'redmine'
        'You must specify your Redmine URL, API token and Project ID'
      when 'pivotal'
        'You must specify your Pivotal Tracker API token and Project ID'
      when 'fogbugz'
        'You must specify your FogBugz Area Name, Username, and Password'
      when 'mingle'
        'You must specify your Mingle URL, Project ID, Card Type (in default card properties), Sign-in name, and Password'
      end
      errors.add(:base, message)
    end
  end

  class << self
    def lighthouseapp_body_template
      @@lighthouseapp_body_template ||= ERB.new(File.read(Rails.root + "app/views/errs/lighthouseapp_body.txt.erb").gsub(/^\s*/, ''))
    end

    def redmine_body_template
      @@redmine_body_template ||= ERB.new(File.read(Rails.root + "app/views/errs/redmine_body.txt.erb"))
    end

    def pivotal_body_template
      @@pivotal_body_template ||= ERB.new(File.read(Rails.root + "app/views/errs/pivotal_body.txt.erb"))
    end

    def fogbugz_body_template
      @@fogbugz_body_template ||= ERB.new(File.read(Rails.root + "app/views/errs/fogbugz_body.txt.erb"))
    end

    def mingle_body_template
      # Mingle also uses textile markup, so the redmine template is perfect.
      redmine_body_template
    end
  end
end

