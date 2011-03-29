class IssueTracker
  include Mongoid::Document
  include Mongoid::Timestamps

  validate :check_lighthouseapp_params
  
  embedded_in :app, :inverse_of => :issue_trackers

  field :account, :type => String
  field :api_token, :type => String
  field :project_id, :type => String
  field :issue_tracker_type, :type => String, :default => 'lighthouseapp'

  protected
  def check_lighthouseapp_params
    errors.add(:base, "You must specify your Lighthouseapp account, token and project id") if %w( api_token project_id account ).map {|m| self[m].blank? }.any?
  end
end
