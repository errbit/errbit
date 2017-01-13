require 'nokogumbo'

# Kramdown escapes certain HTML tags for unknown reasons, but if there are line
# breaks before and after, kramdown understands that these tags are HTML and
# should not be escaped
Jekyll::Hooks.register :pages, :pre_render do |post|
  post.content.gsub!(/(<dl>.*?<\/dl>)/m) do |dl|
    Nokogiri::HTML5.fragment(dl)
  end
  post.content.gsub!('<dt>', "\n<dt>\n")
  post.content.gsub!('</dt>', "\n</dt>\n")
  post.content.gsub!('<dd>', "\n<dd>\n")
  post.content.gsub!('</dd>', "\n</dd>\n")
  post.content.gsub!('<dl>', "\n<dl>\n")
  post.content.gsub!('</dl>', "\n</dl>\n")
end
