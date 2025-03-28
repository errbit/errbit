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

  def gravatar_tag(email, options = {})
    return if email.blank?

    image_tag gravatar_url(email, options), alt: email, class: "gravatar"
  end

  def gravatar_url(email, options = {})
    return if email.blank?

    default_options = {
      d: Errbit::Config.gravatar_default
    }
    options.reverse_merge! default_options
    params = options.extract!(:s, :d).delete_if { |_, v| v.blank? }
    email_hash = Digest::MD5.hexdigest(email)
    url = "https://secure.gravatar.com"
    "#{url}/avatar/#{email_hash}?#{params.to_query}"
  end
end
