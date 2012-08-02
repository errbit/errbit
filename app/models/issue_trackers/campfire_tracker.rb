class IssueTrackers::CampfireTracker < IssueTracker
  Label = "campfire"
  Fields = [
      [:subdomain, {
          :placeholder => "Campfire Subdomain"
      }],
      [:api_token, {
          :placeholder => "API Token"
      }],
      [:project_id, {
          :placeholder => "Room ID",
          :label       => "Room ID"
      }],
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? }
      errors.add :base, 'You must specify your Campfire Subdomain, API token and Room ID'
    end
  end

  def create_issue(problem, reported_by = nil)
    # build the campfire client
    campy = Campy::Room.new(:account => subdomain, :token => api_token, :room_id => project_id)

    # post the issue to the campfire room
    campy.speak "[errbit] http://#{Errbit::Config.host}/apps/#{problem.app.id.to_s} #{issue_title problem}"

    # update the problem to say where it was sent
    problem.update_attributes(
        :issue_link => url,
        :issue_type => Label
    )
  end

  def url
    "http://#{subdomain}.campfirenow.com"
  end
end