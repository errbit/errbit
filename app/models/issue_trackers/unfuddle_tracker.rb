class IssueTrackers::UnfuddleTracker < IssueTracker
  Label = "unfuddle"
  Fields = [

            [:account, {
               :placeholder => "Your domain"
             }],


            [:username, {
               :placeholder => "Your username"
             }],

            [:password, {
               :placeholder => "Your password"
             }],

            [:project_id, {
               :label       => "Ticket Project",
               :placeholder => "Project where tickets will be created"
             }],

            [:milestone_id, {
               :optional    => true,
               :label       => "Ticket Milestone",
               :placeholder => "Milestone where tickets will be created"
             }]


           ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? && !f[1][:optional]}
      errors.add :base, 'You must specify your Account, Username, Password and Project ID'
    end
  end

  def create_issue(problem, reported_by = nil)
    unfuddle = TaskMapper.new(:unfuddle, :username => username, :password => password, :account => account)

    begin
      issue_options = {:project_id => project_id,
        :summary => issue_title(problem),
        :priority => '5',
        :status => "new",
        :description => body_template.result(binding),
        'description-format' => 'textile' }

      issue_options[:milestone_id] = milestone_id if milestone_id.present?

      issue = unfuddle.project(project_id.to_i).ticket!(issue_options)
      problem.update_attributes(
                                :issue_link => File.join("#{url}/tickets/#{issue['id']}"),
                                :issue_type => Label
                                )
    rescue ActiveResource::UnauthorizedAccess
      raise ActiveResource::UnauthorizedAccess, "Could not authenticate with Unfuddle. Please check your username and password."
    end

  end

  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/textile_body.txt.erb"))
  end

  def url
    "https://#{account}.unfuddle.com/projects/#{project_id}"
  end
end
