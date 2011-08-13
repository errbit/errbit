class MingleTracker < IssueTracker
  def self.label; "mingle"; end

  def check_params
    if %w(account project_id username password).detect {|f| self[f].blank? } or !ticket_properties_hash["card_type"]
      errors.add :base, 'You must specify your Mingle URL, Project ID, Card Type (in default card properties), Sign-in name, and Password'
    end
  end

  def create_issue(err)
    properties = ticket_properties_hash
    basic_auth = account.gsub(/https?:\/\//, "https://#{username}:#{password}@")
    Mingle.set_site "#{basic_auth}/api/v1/projects/#{project_id}/"

    card = Mingle::Card.new
    card.card_type_name = properties.delete("card_type")
    card.name = issue_title(err)
    card.description = body_template.result(binding)
    properties.each do |property, value|
      card.send("cp_#{property}=", value)
    end

    card.save!
    err.update_attribute :issue_link, URI.parse("#{account}/projects/#{project_id}/cards/#{card.id}").to_s
  end

  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/textile_body.txt.erb"))
  end

  def ticket_properties_hash
    # Parses 'key=value, key2=value2' from ticket_properties into a ruby hash.
    self.ticket_properties.split(",").inject({}) do |hash, pair|
      key, value = pair.split("=").map(&:strip)
      hash[key] = value
      hash
    end
  end
end

