# frozen_string_literal: true

module ProblemsHelper
  def problem_confirm(action)
    t(format("problems.confirm.%s", action)) unless Errbit::Config.confirm_err_actions.eql? false
  end

  def auto_link_format(body)
    sanitize(
      auto_link(simple_format(body), :all, target: "_blank").html_safe,
      tags: ["a", "p"],
      attributes: ["href", "target"]
    )
  end

  # @param email [String, NilClass] Email
  # @param options [Hash] Options for `gravatar_url()`. Default: {}
  def gravatar_tag(email, options = {})
    return if email.blank?

    image_tag(gravatar_url(email, options), alt: email, class: "gravatar")
  end

  # @param email [String, NilClass] Email
  # @param options [Hash] Extra options. Default: {}
  def gravatar_url(email, options = {})
    return if email.blank?

    default_options = {
      d: Errbit::Config.gravatar_default
    }
    options.reverse_merge!(default_options)
    params = options.extract!(:s, :d).delete_if { |_, v| v.blank? }
    email_hash = Digest::MD5.hexdigest(email)
    url = "https://secure.gravatar.com"
    "#{url}/avatar/#{email_hash}?#{params.to_query}"
  end

  # Generates a structured Markdown snippet from a given notice
  def notice_as_markdown(notice)
    return "" unless notice

    problem = notice.problem
    
    md = []
    # Title & Header
    md << "# #{notice.error_class}: #{notice.message}\n"
    
    # Metadata List
    md << "- **App**: #{problem.app.name}" if problem.app
    md << "- **Environment**: #{problem.environment}"
    md << "- **Where**: #{notice.where}" if notice.where.present?
    md << "- **Occurred at**: #{notice.created_at.to_formatted_s(:db)}"
    md << "- **First notice**: #{problem.first_notice_at&.to_formatted_s(:db)}"
    md << "- **Last notice**: #{problem.last_notice_at&.to_formatted_s(:db)}"
    md << "- **Occurrences**: #{problem.notices_count}\n"
    
    # Backtrace Section
    if notice.backtrace&.lines.present?
      md << "## Backtrace\n"
      md << "```text"
      notice.backtrace.lines.each do |line|
        # Highlight in-app frames if Errbit's model provides helper methods for it
        # Otherwise, output a clean, standard line format
        md << "  #{line.file}:#{line.number} → #{line.method}"
      end
      md << "```\n"
    end

    # Contextual Request/Environment hashes (Omitting empty sections)
    %w(params session user_attributes env_vars).each do |section|
      if notice.respond_to?(section) && (data = notice.send(section)).present?
        md << "## #{section.humanize}\n"
        md << "```ruby"
        md << data.to_yaml.strip.gsub(/^---\s*\n/, '') # Clean YAML-like or Hash output
        md << "```\n"
      end
    end

    md.join("\n")
  end
end
