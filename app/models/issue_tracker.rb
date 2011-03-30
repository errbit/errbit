class IssueTracker
  include Mongoid::Document
  include Mongoid::Timestamps

  validate :check_lighthouseapp_params
  
  embedded_in :app, :inverse_of => :issue_tracker

  field :account, :type => String
  field :api_token, :type => String
  field :project_id, :type => String
  field :issue_tracker_type, :type => String, :default => 'lighthouseapp'

  def create_issue err
    Lighthouse.account = account
    Lighthouse.token = api_token

    ticket = Lighthouse::Ticket.new(:project_id => project_id)
    ticket.title = "[#{ err.where }] #{err.message.to_s.truncate(27)}"
    #ticket.body = err.backtrace.join("\n")
    ticket.tags << "errbit"
    ticket.save
  end

  protected
  def check_lighthouseapp_params
    blank_flags = %w( api_token project_id account ).map {|m| self[m].blank? }
    if blank_flags.any? && !blank_flags.all?
      errors.add(:base, "You must specify your Lighthouseapp account, token and project id")
    end
  end
end
