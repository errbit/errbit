class IssueTrackers::CampfireTracker < IssueTracker
  Label = "campfire"
  Fields = [
      [:account, {
          :placeholder => "Campfire Subdomain"
      }],
      [:api_token, {
          :placeholder => "API Token"
      }],
      [:project_id, {
          :placeholder => "Room ID",
          :label       => "Room ID",
      }],
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify your Campfire subdomain, API token and Room ID'
    end
  end

  def create_issue(problem, reported_by = nil)
    # build the campfire client
    campy = Campy::Room.new(:account => account, :token => api_token, :room_id => project_id)

    # post the issue to the campfire room
    campy.paste issue_title problem

    # update the problem to say where it was sent
    problem.update_attributes(
        :issue_link => "Sent to Campfire",
        :issue_type => Label
    )
  end

  def url
    "http://#{account}.campfirenow.com"
  end
end