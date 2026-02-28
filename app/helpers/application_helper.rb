# frozen_string_literal: true

module ApplicationHelper
  def message_graph(problem)
    create_percentage_table_for(problem.messages)
  end

  def generate_problem_ical(notices)
    calendar = Icalendar::Calendar.new

    notices.each_with_index do |notice, index|
      calendar.event do |event|
        event.summary = "#{index + 1} #{notice.message}"
        event.description = notice.url if notice.url
        event.dtstart = notice.created_at.utc
        event.dtend = notice.created_at.utc + 60.minutes
        event.organizer = notice.server_environment && notice.server_environment["hostname"]
        event.location = notice.project_root
        event.url = app_problem_url(app_id: notice.problem.app.id, id: notice.problem)
      end
    end

    calendar.publish.to_ical
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
      tallies[tally["value"]] = tally["count"]
      tallies
    end
  end

  def create_percentage_table_from_tallies(tallies, options = {})
    total = options[:total] || total_from_tallies(tallies)
    percent = 100.0 / total.to_f
    rows = tallies.map { |value, count| [(count.to_f * percent), value] }
      .sort { |a, b| b[0] <=> a[0] }

    render "problems/tally_table", rows: rows
  end

  def head(collection)
    collection.first(head_size)
  end

  def tail(collection)
    collection.to_a[head_size..].to_a
  end

  def issue_tracker_types
    ErrbitPlugin::Registry.issue_trackers.map do |_, object|
      IssueTrackerTypeDecorator.new(object)
    end
  end

  FA_ICON_MAP = {
    "github" => "fa-brands fa-github",
    "gitlab" => "fa-brands fa-gitlab",
    "bitbucket" => "fa-brands fa-bitbucket",
    "jira" => "fa-brands fa-jira",
    "pivotal" => "fa-solid fa-chart-bar",
    "mingle" => "fa-solid fa-columns",
    "redmine" => "fa-solid fa-bug",
    "fogbugz" => "fa-solid fa-bug-slash",
    "lighthouseapp" => "fa-solid fa-lightbulb",
    "unfuddle" => "fa-solid fa-clipboard-list",
    "slack" => "fa-brands fa-slack",
    "campfire" => "fa-solid fa-fire",
    "pushover" => "fa-solid fa-bell",
    "hubot" => "fa-solid fa-robot",
    "hoiio" => "fa-solid fa-phone",
    "webhook" => "fa-solid fa-globe",
    "none" => "fa-solid fa-ban"
  }.freeze

  def fa_icon_class(label)
    FA_ICON_MAP[label.to_s.downcase] || "fa-solid fa-circle-question"
  end

  def fa_icon(name, prefix: "fa-solid", **options)
    css = "#{prefix} fa-#{name}"
    css = "#{css} #{options.delete(:class)}" if options[:class]
    tag.i(**options, class: css)
  end

  private

  def total_from_tallies(tallies)
    tallies.values.sum
  end

  def head_size
    4
  end
end
