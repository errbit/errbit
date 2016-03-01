module FormHelper
  def errors_for(document)
    return unless document.errors.any?

    content_tag(:div, class: 'error-messages') do
      body = content_tag(:p, t('following_errors_prevent_action'))
      body + content_tag(:ul) do
        document.errors.full_messages.inject('') do |errs, msg|
          errs + content_tag(:li, h(msg))
        end.html_safe
      end
    end
  end

  def label_for_attr(builder, field)
    (builder.object_name + field).gsub(/[\[\]]/, '_').squeeze('_')
  end
end
