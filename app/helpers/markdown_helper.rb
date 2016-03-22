module MarkdownHelper

  def markdown
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML,
      autolink: true,             # parse and identify links
      lax_spacing: true,          # don't require extra line breaks
      space_after_headers: false, # don't require there to be a space between # and a header
      fenced_code_blocks: true,
      no_intra_emphasis: true)    # don't italicize bar in foo_bar_baz
  end

  def mdown(text)
    return "" if text.blank?
    markdown.render(text).html_safe
  end

end
