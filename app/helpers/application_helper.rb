module ApplicationHelper
  
  
  def lighthouse_tracker? object
    object.issue_tracker_type == "lighthouseapp"
  end
  
  def user_agent_graph(error)
    tallies = tally(error.notices) {|notice| pretty_user_agent(notice.user_agent)}
    create_percentage_table(tallies, :total => error.notices.count)
  end
  
  def pretty_user_agent(user_agent)
    (user_agent.nil? || user_agent.none?) ? "N/A" : "#{user_agent.browser} #{user_agent.version}"
  end
  
  def tally(collection, &block)
    collection.inject({}) do |tallies, item|
      value = yield item
      tallies[value] = (tallies[value] || 0) + 1
      tallies
    end
  end
  
  def create_percentage_table(tallies, options={})
    total   = (options[:total] || total_from_tallies(tallies))
    percent = 100.0 / total.to_f
    rows    = tallies.map {|value, count| [(count.to_f * percent), value]} \
                     .sort {|a, b| a[0] <=> b[0]}
    render :partial => "errs/tally_table", :locals => {:rows => rows}
  end
  
  def total_from_tallies(tallies)
    tallies.values.inject(0) {|sum, n| sum + n}
  end
  private :total_from_tallies
  
  def redmine_tracker? object
    object.issue_tracker_type == "redmine"
  end

  def pivotal_tracker? object
    object.issue_tracker_type == "pivotal"
  end
end
