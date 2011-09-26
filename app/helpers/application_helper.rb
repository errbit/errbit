module ApplicationHelper
  
  
  
  def message_graph(problem)
    create_percentage_table_for(problem) {|notice| notice.message}
  end
  
  
  
  def user_agent_graph(problem)
    create_percentage_table_for(problem) {|notice| pretty_user_agent(notice.user_agent)}
  end
  
  def pretty_user_agent(user_agent)
    (user_agent.nil? || user_agent.none?) ? "N/A" : "#{user_agent.browser} #{user_agent.version}"
  end
  
  
  
  def tenant_graph(problem)
    create_percentage_table_for(problem) {|notice| get_host(notice.request['url'])}
  end
  
  def get_host(url)
    uri = url && URI.parse(url)
    uri.blank? ? "N/A" : uri.host
  end
  
  
  
  def create_percentage_table_for(problem, &block)
    tallies = tally(problem.notices, &block)
    create_percentage_table_from_tallies(tallies, :total => problem.notices.count)
  end
  
  def tally(collection, &block)
    collection.inject({}) do |tallies, item|
      value = yield item
      tallies[value] = (tallies[value] || 0) + 1
      tallies
    end
  end
  
  def create_percentage_table_from_tallies(tallies, options={})
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
  
  
end

