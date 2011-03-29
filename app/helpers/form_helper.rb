module FormHelper
  
  def errors_for(document)
    return unless document.errors.any?
    
    content_tag(:div, :class => 'error-messages') do
      body  = content_tag(:h2, 'Dang. The following errors are keeping this from being a success.')
      body += content_tag(:ul) do
        document.errors.full_messages.inject('') {|errs, msg| errs += content_tag(:li, h(msg)) }.html_safe
      end
    end
  end
  
  def label_for_attr(builder, field)
    (builder.object_name + field).gsub(/[\[\]]/,'_').squeeze('_')
  end
  
end