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
    emojify markdown.render(text).html_safe
  end

  def emojify(content)
    h(content).to_str.gsub(/:([\w+-]+):/) do |match|
      if emoji = Emoji.find_by_alias($1)
        %(<img alt="#$1" src="#{image_path("emoji/#{emoji.image_filename}")}" style="vertical-align:middle" width="20" height="20" />)
      else
        match
      end
    end.html_safe if content.present?
  end

end
