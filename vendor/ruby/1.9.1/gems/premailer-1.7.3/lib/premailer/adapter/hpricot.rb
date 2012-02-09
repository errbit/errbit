require 'hpricot'

class Premailer
  module Adapter
    module Hpricot

      # Merge CSS into the HTML document.
      #
      # Returns a string.
      def to_inline_css
        doc = @processed_doc
        @unmergable_rules = CssParser::Parser.new

        # Give all styles already in style attributes a specificity of 1000
        # per http://www.w3.org/TR/CSS21/cascade.html#specificity
        doc.search("*[@style]").each do |el|
          el['style'] = '[SPEC=1000[' + el.attributes['style'] + ']]'
        end

        # Iterate through the rules and merge them into the HTML
        @css_parser.each_selector(:all) do |selector, declaration, specificity|
          # Save un-mergable rules separately
          selector.gsub!(/:link([\s]*)+/i) {|m| $1 }

          # Convert element names to lower case
          selector.gsub!(/([\s]|^)([\w]+)/) {|m| $1.to_s + $2.to_s.downcase }

          if selector =~ Premailer::RE_UNMERGABLE_SELECTORS
            @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selector, declaration)) unless @options[:preserve_styles]
          else
            begin
	            if selector =~ Premailer::RE_RESET_SELECTORS
                # this is in place to preserve the MailChimp CSS reset: http://github.com/mailchimp/Email-Blueprints/
                # however, this doesn't mean for testing pur
	              @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selector, declaration))  unless !@options[:preserve_reset]
              end

              # Change single ID CSS selectors into xpath so that we can match more
              # than one element.  Added to work around dodgy generated code.
              selector.gsub!(/\A\#([\w_\-]+)\Z/, '*[@id=\1]')
              
              # convert attribute selectors to hpricot's format
              selector.gsub!(/\[([\w]+)\]/, '[@\1]')
              selector.gsub!(/\[([\w]+)([\=\~\^\$\*]+)([\w\s]+)\]/, '[@\1\2\'\3\']')

              doc.search(selector).each do |el|
                if el.elem? and (el.name != 'head' and el.parent.name != 'head')
                  # Add a style attribute or append to the existing one
                  block = "[SPEC=#{specificity}[#{declaration}]]"
                  el['style'] = (el.attributes['style'].to_s ||= '') + ' ' + block
                end
              end
            rescue ::Hpricot::Error, RuntimeError, ArgumentError
              $stderr.puts "CSS syntax error with selector: #{selector}" if @options[:verbose]
              next
            end
          end
        end

        # Read STYLE attributes and perform folding
        doc.search("*[@style]").each do |el|
          style = el.attributes['style'].to_s

          declarations = []

          style.scan(/\[SPEC\=([\d]+)\[(.[^\]\]]*)\]\]/).each do |declaration|
            rs = CssParser::RuleSet.new(nil, declaration[1].to_s, declaration[0].to_i)
            declarations << rs
          end
          # Perform style folding
          merged = CssParser.merge(declarations)
          merged.expand_shorthand!

          # Duplicate CSS attributes as HTML attributes
          if Premailer::RELATED_ATTRIBUTES.has_key?(el.name)
            Premailer::RELATED_ATTRIBUTES[el.name].each do |css_att, html_att|
              el[html_att] = merged[css_att].gsub(/;$/, '').strip if el[html_att].nil? and not merged[css_att].empty?
            end
          end

          merged.create_dimensions_shorthand!
          merged.create_border_shorthand!

          # write the inline STYLE attribute
          el['style'] = Premailer.escape_string(merged.declarations_to_s)
        end

        doc = write_unmergable_css_rules(doc, @unmergable_rules)

        if @options[:remove_classes] or @options[:remove_comments]
          doc.search('*').each do |el|
            if el.comment? and @options[:remove_comments]
              lst = el.parent.children
              el.parent = nil
              lst.delete(el)
            elsif el.elem?
              el.remove_attribute('class') if @options[:remove_classes]
            end
          end
        end

        if @options[:remove_ids]
          # find all anchor's targets and hash them
          targets = []
          doc.search("a[@href^='#']").each do |el|
            target = el.get_attribute('href')[1..-1]
            targets << target
            el.set_attribute('href', "#" + Digest::MD5.hexdigest(target))
          end
          # hash ids that are links target, delete others
          doc.search("*[@id]").each do |el|
            id = el.get_attribute('id')
            if targets.include?(id)
              el.set_attribute('id', Digest::MD5.hexdigest(id))
            else
              el.remove_attribute('id')
            end
          end
        end

        @processed_doc = doc

        @processed_doc.to_original_html
      end

      # Create a <tt>style</tt> element with un-mergable rules (e.g. <tt>:hover</tt>)
      # and write it into the <tt>body</tt>.
      #
      # <tt>doc</tt> is an Hpricot document and <tt>unmergable_css_rules</tt> is a Css::RuleSet.
      #
      # Returns an Hpricot document.
      def write_unmergable_css_rules(doc, unmergable_rules) # :nodoc:
        styles = ''
        unmergable_rules.each_selector(:all, :force_important => true) do |selector, declarations, specificity|
          styles += "#{selector} { #{declarations} }\n"
        end

        unless styles.empty?
          style_tag = "\n<style type=\"text/css\">\n#{styles}</style>\n"
          if body = doc.search('body')
            body.append(style_tag)
          else
            doc.inner_html= doc.inner_html << style_tag
          end
        end
        doc
      end


      # Converts the HTML document to a format suitable for plain-text e-mail.
      #
      # If present, uses the <body> element as its base; otherwise uses the whole document.
      #
      # Returns a string.
      def to_plain_text
        html_src = ''
        begin
          html_src = @doc.search("body").inner_html
        rescue; end

        html_src = @doc.to_html unless html_src and not html_src.empty?
        convert_to_text(html_src, @options[:line_length], @html_encoding)
      end


      # Returns the original HTML as a string.
      def to_s
        @doc.to_original_html
      end

      # Load the HTML file and convert it into an Hpricot document.
      #
      # Returns an Hpricot document.
      def load_html(input) # :nodoc:
        thing = nil

        # TODO: duplicate options
        if @options[:with_html_string] or @options[:inline] or input.respond_to?(:read)
          thing = input
				elsif @is_local_file
          @base_dir = File.dirname(input)
          thing = File.open(input, 'r')
				else
          thing = open(input)
        end

        # TODO: deal with Hpricot seg faults on empty input
        thing ? Hpricot(thing) : nil
      end

    end
  end
end
