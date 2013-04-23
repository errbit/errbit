module ProblemsHelper
  def problem_confirm
    Errbit::Config.confirm_resolve_err === false ? nil : 'Seriously?'
  end

  def truncated_problem_message(problem)
    unless (msg = problem.message).blank?
      # Truncate & insert invisible chars so that firefox can emulate 'word-wrap: break-word' CSS rule
      truncate(msg, :length => 300).scan(/.{1,5}/).map { |s| h(s) }.join("&#8203;").html_safe
    end
  end

  def gravatar_tag(email, options = {})
    return nil unless email.present?
    
    image_tag gravatar_url(email, options), :alt => email, :class => 'gravatar'
  end

  def gravatar_url(email, options = {})
    return nil unless email.present?

    default_options = {
      :d => Errbit::Config.gravatar_default,
    }
    options.reverse_merge! default_options
    params = options.extract!(:s, :d).delete_if { |k, v| v.blank? }
    email_hash = Digest::MD5.hexdigest(email)
    "http://www.gravatar.com/avatar/#{email_hash}?#{params.to_query}"
  end
end

