module MarkdownHelper

  def mdown(text)
    text = text.body if text.respond_to?(:body)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true)
    markdown.render(text).html_safe
  end

end
