# Used for parsing a document in kramdown format.
#
# If you want to extend the functionality of the parser, you need to do the following:
#
# * Create a new subclass
# * add the needed parser methods
# * modify the @block_parsers and @span_parsers variables and add the names of your parser
#   methods
#
# Here is a small example for an extended parser class that parses ERB style tags as raw text if
# they are used as span-level elements (an equivalent block-level parser should probably also be
# made to handle the block case):
#
require 'kramdown/parser/gfm'

class Kramdown::Parser::DocParser < Kramdown::Parser::GFM
   # def initialize(source, options)
   #   super
   #   @span_parsers.unshift(:erb_tags)
   # end

   # ERB_TAGS_START = /<%.*?%>/
   HTML_TAG_RE = /<((?>#{REXML::Parsers::BaseParser::UNAME_STR}))\s*((?>\s+#{REXML::Parsers::BaseParser::UNAME_STR}(?:\s*=\s*(["']).*?\3)?)*)\s*(\/)?>/m
   HTML_TAG_CLOSE_RE = /<\/(#{REXML::Parsers::BaseParser::UNAME_STR})\s*>/m

   def parse_block_html
     line = @src.current_line_number
     if result = @src.scan(HTML_COMMENT_RE)
       @tree.children << Element.new(:xml_comment, result, nil, :category => :block, :location => line)
       @src.scan(TRAILING_WHITESPACE)
       true
     elsif result = @src.scan(HTML_INSTRUCTION_RE)
       @tree.children << Element.new(:xml_pi, result, nil, :category => :block, :location => line)
       @src.scan(TRAILING_WHITESPACE)
       true
     else
       if result = @src.check(/^#{OPT_SPACE}#{HTML_TAG_RE}/) && !HTML_SPAN_ELEMENTS.include?(@src[1].downcase)
         @src.pos += @src.matched_size
         handle_html_start_tag(line, &method(:handle_kramdown_html_tag))
         Kramdown::Parser::Html::ElementConverter.convert(@root, @tree.children.last) if @options[:html_to_native]
         true
       elsif result = @src.check(/^#{OPT_SPACE}#{HTML_TAG_CLOSE_RE}/) && !HTML_SPAN_ELEMENTS.include?(@src[1].downcase)
         name = @src[1].downcase

         if @tree.type == :html_element && @tree.value == name
           @src.pos += @src.matched_size
           throw :stop_block_parsing, :found
         else
           false
         end
       else
         false
       end
     end





       # @tree.children << Element.new(:xml_comment, result, nil, :category => :block, :location => line)
       # @src.scan(TRAILING_WHITESPACE)
       # true

     binding.pry
     # 1
     @tree.children << Element.new(:raw, 'foo')
   end
   # define_parser(:erb_tags, ERB_TAGS_START, '<%')
end
#
# The new parser can be used like this:
#
#   require 'kramdown/document'
#   # require the file with the above parser class
#
#   Kramdown::Document.new(input_text, :input => 'ERBKramdown').to_html
