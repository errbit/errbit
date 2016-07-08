# nasty hack to exert control over link handling. Github magically handles
# internal, relative links, but in a way that isn't compatible with this docs
# site.
module Kramdown
  module Parser
    class Kramdown
      def add_link_with_rel_parse(el, href, title, alt_text = nil, ial = nil)
        new_href = href.sub(/^docs\/(.*).md$/, '\1.html')
        # binding.pry if href.match(/^docs\/(.*).md$/)
        add_link_without_rel_parse(el, new_href, title, alt_text, ial)
      end
      alias_method :add_link_without_rel_parse, :add_link
      alias_method :add_link, :add_link_with_rel_parse
    end
  end
end
