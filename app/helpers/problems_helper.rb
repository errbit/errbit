module ProblemsHelper
  def problem_confirm(action)
    t(format('problems.confirm.%s', action)) unless Errbit::Config.confirm_err_actions.eql? false
  end

  def gravatar_tag(email, options = {})
    return nil unless email.present?

    image_tag gravatar_url(email, options), alt: email, class: 'gravatar'
  end

  def gravatar_url(email, options = {})
    return nil unless email.present?

    default_options = {
      d: Errbit::Config.gravatar_default
    }
    options.reverse_merge! default_options
    params = options.extract!(:s, :d).delete_if { |_k, v| v.blank? }
    email_hash = Digest::MD5.hexdigest(email)
    url = request.ssl? ? "https://secure.gravatar.com" : "http://www.gravatar.com"
    "#{url}/avatar/#{email_hash}?#{params.to_query}"
  end
end
