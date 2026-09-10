# frozen_string_literal: true

module McpServer
  module Tools
    # rubocop:disable Metrics/ClassLength
    class GetIncidentSummary < MCP::Tool
      DEFAULT_LIMIT = 10
      MAX_LIMIT = 25
      MAX_PAYLOAD_BYTES = 1_000_000
      tool_name "errbit_get_incident_summary"
      description "Return deterministic aggregate facts for matching Errbit problems."
      annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false
      input_schema(
        properties: {
          app_id: {type: "string", minLength: 1, maxLength: 100},
          app_name: {type: "string", minLength: 1, maxLength: 200},
          environment: {type: "string", minLength: 1, maxLength: 100},
          resolved: {type: "boolean"},
          problem_id: {type: "string", minLength: 1, maxLength: 100},
          search: {type: "string", minLength: 1, maxLength: 200},
          since: {type: "string", format: "date-time"},
          until: {type: "string", format: "date-time"},
          limit: {type: "integer", minimum: 1, maximum: MAX_LIMIT}
        }
      )
      class << self
        def call(**arguments)
          since = parse_time(arguments[:since])
          until_time = parse_time(arguments[:until])
          return ToolResponse.error(error: "invalid_date_range") if since && until_time && since > until_time

          result = summary(arguments, since, until_time)
          return ToolResponse.error(error: "summary_too_large", max_bytes: MAX_PAYLOAD_BYTES) if result.to_json.bytesize > MAX_PAYLOAD_BYTES

          ToolResponse.success(result)
        rescue Mongoid::Errors::DocumentNotFound
          ToolResponse.error(error: "problem_not_found", problem_id: arguments[:problem_id])
        rescue ArgumentError, TypeError
          ToolResponse.error(error: "invalid_date_range")
        end

        private

        def summary(arguments, since, until_time)
          matching = filtered_problems(arguments, since, until_time).to_a
          limit = arguments.fetch(:limit, DEFAULT_LIMIT)

          summary_counts(matching).merge(
            summary_lists(matching, limit)
          )
        end

        def summary_counts(problems)
          {
            matching_problem_count: problems.size,
            total_notice_count: problems.sum { |problem| problem.notices_count.to_i },
            resolved_problem_count: problems.count(&:resolved?),
            unresolved_problem_count: problems.count(&:unresolved?)
          }
        end

        def summary_lists(matching, limit)
          latest = latest_problems(matching)
          problem_lists(latest, frequent_problems(matching), limit)
            .merge(frequency_lists(matching, limit))
            .merge(notice_lists(latest, limit))
        end

        def latest_problems(problems)
          problems.sort_by { |problem| [-problem.last_notice_at.to_i, problem.id.to_s] }
        end

        def frequent_problems(problems)
          problems.sort_by { |problem| [-problem.notices_count.to_i, problem.id.to_s] }
        end

        def problem_lists(latest, frequent, limit)
          {
            latest_affected_problems: latest.first(limit).map { |problem| ProblemPresenter.summary(problem) },
            highest_frequency_problems: frequent.first(limit).map { |problem| ProblemPresenter.summary(problem) }
          }
        end

        def frequency_lists(problems, limit)
          {
            top_error_classes: frequencies(problems, :error_class, limit),
            top_environments: frequencies(problems, :environment, limit)
          }
        end

        def notice_lists(problems, limit)
          {representative_latest_notices: problems.first(limit).filter_map { |problem| notice_summary(problem) }}
        end

        def filtered_problems(arguments, since, until_time)
          problems = Problem.all
          filters = arguments.slice(:app_id, :app_name, :environment, :problem_id).compact
          problems = problems.where(filters) if filters.any?
          apply_filters(problems, arguments, since, until_time)
        end

        def apply_filters(problems, arguments, since, until_time)
          problems = arguments[:resolved] ? problems.resolved : problems.unresolved unless arguments[:resolved].nil?
          problems = problems.search(arguments[:search]) if arguments[:search]
          problems = problems.where(:last_notice_at.gte => since) if since
          problems = problems.where(:first_notice_at.lte => until_time) if until_time
          problems
        end

        def parse_time(value)
          return if value.blank?

          Time.zone.parse(value.to_s)
        end

        def frequencies(problems, attribute, limit)
          problems.group_by { |problem| problem.public_send(attribute).to_s }.map { |value, items| {value: value, count: items.size} }
            .sort_by { |item| [-item[:count], item[:value]] }
            .first(limit)
        end

        def notice_summary(problem)
          notice = Notice.for_errs(problem.errs).reverse_ordered.first
          NoticePresenter.summary(notice) if notice
        end
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
