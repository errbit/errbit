class IssueTrackers::MingleTracker < IssueTracker
  Label = "mingle"
  Fields = [
    [:account, {
      :label       => "Mingle URL",
      :placeholder => "abc from http://abc.fogbugz.com/"
    }],
    [:project_id, {
      :placeholder => "Mingle project"
    }],
    [:ticket_properties, {
      :label       => "Card Properties (comma separated key=value pairs)",
      :placeholder => "card_type = Defect, defect_status = Open, priority = Essential"
    }],
    [:username, {
      :label       => "Sign-in name",
      :placeholder => "Sign-in name for your account"
    }],
    [:password, {
      :placeholder => "Password for your account"
    }]
  ]

  def check_params
    if Fields.detect {|f| self[f[0]].blank? } or !ticket_properties_hash["card_type"]
      errors.add :base, 'You must specify your Mingle URL, Project ID, Card Type (in default card properties), Sign-in name, and Password'
    end
  end

  def create_issue(problem)
    properties = ticket_properties_hash
    basic_auth = account.gsub(/https?:\/\//, "https://#{username}:#{password}@")
    Mingle.set_site "#{basic_auth}/api/v1/projects/#{project_id}/"

    card = Mingle::Card.new
    card.card_type_name = properties.delete("card_type")
    card.name = issue_title(problem)
    card.description = body_template.result(binding)
    properties.each do |property, value|
      card.send("cp_#{property}=", value)
    end

    card.save!
    problem.update_attribute :issue_link, URI.parse("#{account}/projects/#{project_id}/cards/#{card.id}").to_s
  end

  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/textile_body.txt.erb"))
  end

  def ticket_properties_hash
    # Parses 'key=value, key2=value2' from ticket_properties into a ruby hash.
    self.ticket_properties.to_s.split(",").inject({}) do |hash, pair|
      key, value = pair.split("=").map(&:strip)
      hash[key] = value
      hash
    end
  end
end

