module ApplicationHelper
  def message_graph(problem)
    create_percentage_table_for(problem.messages)
  end

  def generate_problem_ical(notices)
    RiCal.Calendar do |cal|
      notices.each_with_index do |notice,idx|
        cal.event do |event|
          event.summary     = "#{idx+1} #{notice.message.to_s}"
          event.description = notice.url if notice.url
          event.dtstart     = notice.created_at.utc
          event.dtend       = notice.created_at.utc + 60.minutes
          event.organizer   = notice.server_environment && notice.server_environment["hostname"]
          event.location    = notice.project_root
          event.url         = app_problem_url(:app_id => notice.problem.app.id, :id => notice.problem)
        end
      end
    end.to_s
  end

  def generate_ical(deploys)
    RiCal.Calendar { |cal|
      deploys.each_with_index do |deploy,idx|
        cal.event do |event|
          event.summary     = "#{idx+1} #{deploy.repository.to_s}"
          event.description = deploy.revision.to_s
          event.dtstart     = deploy.created_at.utc
          event.dtend       = deploy.created_at.utc + 60.minutes
          event.location    = deploy.environment.to_s
          event.organizer   = deploy.username.to_s
        end
      end
    }.to_s
  end

  def user_agent_graph(problem)
    create_percentage_table_for(problem.user_agents)
  end

  def tenant_graph(problem)
    create_percentage_table_for(problem.hosts)
  end

  def create_percentage_table_for(collection)
    create_percentage_table_from_tallies(tally(collection))
  end

  def tally(collection)
    collection.values.inject({}) do |tallies, tally|
      tallies[tally['value']] = tally['count']
      tallies
    end
  end

  def create_percentage_table_from_tallies(tallies, options={})
    total   = (options[:total] || total_from_tallies(tallies))
    percent = 100.0 / total.to_f
    rows    = tallies.map {|value, count| [(count.to_f * percent), value]} \
                     .sort {|a, b| b[0] <=> a[0]}
    render "problems/tally_table", :rows => rows
  end

  def head(collection)
    collection.first(head_size)
  end

  def tail(collection)
    collection.to_a[head_size..-1].to_a
  end

  private
    def total_from_tallies(tallies)
      tallies.values.inject(0) {|sum, n| sum + n}
    end

    def head_size
      4
    end

end

