# Premailer by Alex Dunae (dunae.ca, e-mail 'code' at the same domain), 2008-10
#
# Premailer processes HTML and CSS to improve e-mail deliverability.
#
# Premailer's main function is to render all CSS as inline <tt>style</tt>
# attributes. It also converts relative links to absolute links and checks
# the 'safety' of CSS properties against a CSS support chart.
#
# = Example
#  premailer = Premailer.new('http://example.com/myfile.html', :warn_level => Premailer::Warnings::SAFE)
#
#  # Write the HTML output
#  fout = File.open("output.html", "w")
#  fout.puts premailer.to_inline_css
#  fout.close
#
#  # Write the plain-text output
#  fout = File.open("ouput.txt", "w")
#  fout.puts premailer.to_plain_text
#  fout.close
#
#  # List any CSS warnings
#  puts premailer.warnings.length.to_s + ' warnings found'
#  premailer.warnings.each do |w|
#    puts "#{w[:message]} (#{w[:level]}) may not render properly in #{w[:clients]}"
#  end
#
#  premailer = Premailer.new(html_file, :warn_level => Premailer::Warnings::SAFE)
#  puts premailer.to_inline_css
class Premailer
  include HtmlToPlainText
  include CssParser

  VERSION = '1.7.3'

  CLIENT_SUPPORT_FILE = File.dirname(__FILE__) + '/../../misc/client_support.yaml'

  RE_UNMERGABLE_SELECTORS = /(\:(visited|active|hover|focus|after|before|selection|target|first\-(line|letter))|^\@)/i
  RE_RESET_SELECTORS = /^(\:\#outlook|body.*|\.ReadMsgBody|\.ExternalClass|img|\#backgroundTable)$/

  # list of CSS attributes that can be rendered as HTML attributes
  #
  # TODO: too much repetition
  # TODO: background=""
  RELATED_ATTRIBUTES = {
    'h1' => {'text-align' => 'align'},
    'h2' => {'text-align' => 'align'},
    'h3' => {'text-align' => 'align'},
    'h4' => {'text-align' => 'align'},
    'h5' => {'text-align' => 'align'},
    'h6' => {'text-align' => 'align'},
    'p' => {'text-align' => 'align'},
    'div' => {'text-align' => 'align'},
    'blockquote' => {'text-align' => 'align'},
    'body' => {'background-color' => 'bgcolor'},
    'table' => {
      'background-color' => 'bgcolor',
      '-premailer-width' => 'width',
      '-premailer-height' => 'height',
      '-premailer-cellpadding' => 'cellpadding',
      '-premailer-cellspacing' => 'cellspacing',
    },
    'tr' => {
      'text-align' => 'align',
      'background-color' => 'bgcolor',
      '-premailer-height' => 'height'
    },
    'th' => {
      'text-align' => 'align',
      'background-color' => 'bgcolor',
      'vertical-align' => 'valign',
      '-premailer-width' => 'width',
      '-premailer-height' => 'height'
    },
    'td' => {
      'text-align' => 'align',
      'background-color' => 'bgcolor',
      'vertical-align' => 'valign',
      '-premailer-width' => 'width',
      '-premailer-height' => 'height',
      '-premailer-colspan' => 'colspan'
    },
    'img' => {'float' => 'align'}
  }

  # URI of the HTML file used
  attr_reader   :html_file

  # base URL used to resolve links
  attr_reader   :base_url

  # base directory used to resolve links for local files
  attr_reader   :base_dir

  # unmergeable CSS rules to be preserved in the head (CssParser)
  attr_reader   :unmergable_rules

  # processed HTML document (Hpricot/Nokogiri)
  attr_reader   :processed_doc

  # source HTML document (Hpricot/Nokogiri)
  attr_reader   :doc

  module Warnings
    NONE = 0
    SAFE = 1
    POOR = 2
    RISKY = 3
  end
  include Warnings

  WARN_LABEL = %w(NONE SAFE POOR RISKY)

  # Create a new Premailer object.
  #
  # +html+ is the HTML data to process. It can be either an IO object, the URL of a
  # remote file, a local path or a raw HTML string.  If passing an HTML string you
  # must set the +:with_html_string+ option to +true+.
  #
  # ==== Options
  # [+line_length+] Line length used by to_plain_text. Boolean, default is 65.
  # [+warn_level+] What level of CSS compatibility warnings to show (see Warnings).
  # [+link_query_string+] A string to append to every <tt>a href=""</tt> link. Do not include the initial <tt>?</tt>.
  # [+base_url+] Used to calculate absolute URLs for local files.
  # [+css+] Manually specify CSS stylesheets.
  # [+css_to_attributes+] Copy related CSS attributes into HTML attributes (e.g. +background-color+ to +bgcolor+)
  # [+css_string+] Pass CSS as a string
  # [+remove_ids+] Remove ID attributes whenever possible and convert IDs used as anchors to hashed to avoid collisions in webmail programs.  Default is +false+.
  # [+remove_classes+] Remove class attributes. Default is +false+.
  # [+remove_comments+] Remove html comments. Default is +false+.
  # [+preserve_styles+] Whether to preserve any <tt>link rel=stylesheet</tt> and <tt>style</tt> elements.  Default is +false+.
  # [+preserve_reset+] Whether to preserve styles associated with the MailChimp reset code
  # [+with_html_string+] Whether the +html+ param should be treated as a raw string.
  # [+verbose+] Whether to print errors and warnings to <tt>$stderr</tt>.  Default is +false+.
  # [+adapter+] Which HTML parser to use, either <tt>:nokogiri</tt> or <tt>:hpricot</tt>.  Default is <tt>:hpricot</tt>.
  def initialize(html, options = {})
    @options = {:warn_level => Warnings::SAFE,
                :line_length => 65,
                :link_query_string => nil,
                :base_url => nil,
                :remove_classes => false,
                :remove_ids => false,
                :remove_comments => false,
                :css => [],
                :css_to_attributes => true,
                :with_html_string => false,
                :css_string => nil,
                :preserve_styles => false,
                :preserve_reset => true,
                :verbose => false,
                :debug => false,
                :io_exceptions => false,
                :adapter => Adapter.use}.merge(options)

    @html_file = html
    @is_local_file = @options[:with_html_string] || Premailer.local_data?(html)

    @css_files = [@options[:css]].flatten

    @css_warnings = []

    @base_url = nil
    @base_dir = nil
    @unmergable_rules = nil

    if @options[:base_url]
      @base_url = URI.parse(@options.delete(:base_url))
    elsif not @is_local_file
      @base_url = URI.parse(@html_file)
    end

    @css_parser = CssParser::Parser.new({
      :absolute_paths => true,
      :import => true,
      :io_exceptions => @options[:io_exceptions]
    })

    @adapter_class = Adapter.find @options[:adapter]

    self.class.send(:include, @adapter_class)

    @doc = load_html(@html_file)

    @processed_doc = @doc
    @processed_doc = convert_inline_links(@processed_doc, @base_url) if @base_url
    if options[:link_query_string]
      @processed_doc = append_query_string(@processed_doc, options[:link_query_string])
    end
    load_css_from_options!
    load_css_from_html!
  end

  # Array containing a hash of CSS warnings.
  def warnings
    return [] if @options[:warn_level] == Warnings::NONE
    @css_warnings = check_client_support if @css_warnings.empty?
    @css_warnings
  end

protected
  def load_css_from_local_file!(path)
    css_block = ''
    begin
      File.open(path, "r") do |file|
        while line = file.gets
          css_block << line
        end
      end

      load_css_from_string(css_block)
    rescue; end
  end

  def load_css_from_string(css_string)
    @css_parser.add_block!(css_string, {:base_uri => @base_url, :base_dir => @base_dir, :only_media_types => [:screen, :handheld]})
  end

  def load_css_from_options! # :nodoc:
    load_css_from_string(@options[:css_string]) if @options[:css_string]

    @css_files.each do |css_file|
      if Premailer.local_data?(css_file)
        load_css_from_local_file!(css_file)
      else
        @css_parser.load_uri!(css_file)
      end
    end
  end

    # Load CSS included in <tt>style</tt> and <tt>link</tt> tags from an HTML document.
  def load_css_from_html! # :nodoc:
    if tags = @doc.search("link[@rel='stylesheet'], style")
      tags.each do |tag|
        if tag.to_s.strip =~ /^\<link/i && tag.attributes['href'] && media_type_ok?(tag.attributes['media'])
          # A user might want to <link /> to a local css file that is also mirrored on the site
          # but the local one is different (e.g. newer) than the live file, premailer will now choose the local file
          
          if tag.attributes['href'].to_s.include? @base_url.to_s and @html_file.kind_of?(String)
            link_uri = File.join(File.dirname(@html_file), tag.attributes['href'].to_s.sub!(@base_url.to_s, ''))
          end
          
          # if the file does not exist locally, try to grab the remote reference
          if link_uri.nil? or not File.exists?(link_uri)
            link_uri = Premailer.resolve_link(tag.attributes['href'].to_s, @html_file)
          end
          
          if Premailer.local_data?(link_uri)
            $stderr.puts "Loading css from local file: " + link_uri if @options[:verbose]
            load_css_from_local_file!(link_uri)
          else
            $stderr.puts "Loading css from uri: " + link_uri if @options[:verbose]
            @css_parser.load_uri!(link_uri, {:only_media_types => [:screen, :handheld]})
          end

        elsif tag.to_s.strip =~ /^\<style/i
          @css_parser.add_block!(tag.inner_html, :base_uri => @base_url, :base_dir => @base_dir, :only_media_types => [:screen, :handheld])
        end
      end
      tags.remove unless @options[:preserve_styles]
    end
  end



# here be deprecated methods
public
  def local_uri?(uri) # :nodoc:
    warn "[DEPRECATION] `local_uri?` is deprecated.  Please use `Premailer.local_data?` instead."
    Premailer.local_data?(uri)
  end

# here be instance methods

  def media_type_ok?(media_types) # :nodoc:
    return true if media_types.nil? or media_types.empty?
    media_types.split(/[\s]+|,/).any? { |media_type| media_type.strip =~ /screen|handheld|all/i }
  rescue
    true
  end

  def append_query_string(doc, qs)
    return doc if qs.nil?

    qs.to_s.gsub!(/^[\?]*/, '').strip!
    return doc if qs.empty?

    begin
      current_host = @base_url.host
    rescue
      current_host = nil
    end

    $stderr.puts "Attempting to append_query_string: #{qs}" if @options[:verbose]

    doc.search('a').each do|el|
      href = el.attributes['href'].to_s.strip
      next if href.nil? or href.empty?
      
      next if href[0,1] =~ /[\#\{\[\<\%]/ # don't bother with anchors or special-looking links

      begin
        href = URI.parse(href)

        if current_host and href.host != nil and href.host != current_host
          $stderr.puts "Skipping append_query_string for: #{href.to_s} because host is no good" if @options[:verbose]
          next
        end

        if href.scheme and href.scheme != 'http' and href.scheme != 'https'
          puts "Skipping append_query_string for: #{href.to_s} because scheme is no good" if @options[:verbose]
          next
        end

        if href.query and not href.query.empty?
          href.query = href.query + '&amp;' + qs
        else
          href.query = qs
        end

        el['href'] = href.to_s
      rescue URI::Error => e
        $stderr.puts "Skipping append_query_string for: #{href.to_s} (#{e.message})" if @options[:verbose]
        next
      end

    end
    doc
  end

    # Check for an XHTML doctype
  def is_xhtml?
    intro = @doc.to_html.strip.split("\n")[0..2].join(' ')
    is_xhtml = !!(intro =~ /w3c\/\/[\s]*dtd[\s]+xhtml/i)
    $stderr.puts "Is XHTML? #{is_xhtml.inspect}\nChecked:\n#{intro}" if @options[:debug]
    is_xhtml
  end

    # Convert relative links to absolute links.
  #
  # Processes <tt>href</tt> <tt>src</tt> and <tt>background</tt> attributes
  # as well as CSS <tt>url()</tt> declarations found in inline <tt>style</tt> attributes.
  #
  # <tt>doc</tt> is an Hpricot document and <tt>base_uri</tt> is either a string or a URI.
  #
  # Returns an Hpricot document.
  def convert_inline_links(doc, base_uri) # :nodoc:
    base_uri = URI.parse(base_uri) unless base_uri.kind_of?(URI)

    append_qs = @options[:link_query_string] || ''

    ['href', 'src', 'background'].each do |attribute|
      tags = doc.search("*[@#{attribute}]")

      next if tags.empty?

      tags.each do |tag|
        # skip links that look like they have merge tags
        # and mailto, ftp, etc...
        if tag.attributes[attribute].to_s =~ /^([\%\<\{\#\[]|data:|tel:|file:|sms:|callto:|facetime:|mailto:|ftp:|gopher:)/i
          next
        end

        if tag.attributes[attribute].to_s =~ /^http/i
          begin
            merged = URI.parse(tag.attributes[attribute])
          rescue; next; end
        else
          begin
            merged = Premailer.resolve_link(tag.attributes[attribute].to_s, base_uri)
          rescue
            begin
              merged = Premailer.resolve_link(URI.escape(tag.attributes[attribute].to_s), base_uri)
            rescue; end
          end
        end

        # make sure 'merged' is a URI
        merged = URI.parse(merged.to_s) unless merged.kind_of?(URI)
        tag[attribute] = merged.to_s
      end # end of each tag
    end # end of each attrs

    doc.search("*[@style]").each do |el|
      el['style'] = CssParser.convert_uris(el.attributes['style'].to_s, base_uri)
    end
    doc
  end


  def self.escape_string(str) # :nodoc:
    str.gsub(/"/ , "'")
  end

  def self.resolve_link(path, base_path) # :nodoc:
    path.strip!
    resolved = nil
    if path =~ /(http[s]?|ftp):\/\//i
      resolved = path
      Premailer.canonicalize(resolved)
    elsif base_path.kind_of?(URI)
      resolved = base_path.merge(path)
      Premailer.canonicalize(resolved)
    elsif base_path.kind_of?(String) and base_path =~ /^(http[s]?|ftp):\/\//i
      resolved = URI.parse(base_path)
      resolved = resolved.merge(path)
      Premailer.canonicalize(resolved)
    else
      File.expand_path(path, File.dirname(base_path))
    end
  end

  # Test the passed variable to see if we are in local or remote mode.
  #
  # IO objects return true, as do strings that look like URLs.
  def self.local_data?(data)
    return true if data.is_a?(IO) || data.is_a?(StringIO)
    return false if data =~ /^(http|https|ftp)\:\/\//i
    true
  end

  # from http://www.ruby-forum.com/topic/140101
  def self.canonicalize(uri) # :nodoc:
    u = uri.kind_of?(URI) ? uri : URI.parse(uri.to_s)
    u.normalize!
    newpath = u.path
    while newpath.gsub!(%r{([^/]+)/\.\./?}) { |match|
        $1 == '..' ? match : ''
      } do end
      newpath = newpath.gsub(%r{/\./}, '/').sub(%r{/\.\z}, '/')
      u.path = newpath
      u.to_s
    end

  # Check <tt>CLIENT_SUPPORT_FILE</tt> for any CSS warnings
  def check_client_support # :nodoc:
    @client_support ||= YAML::load(File.open(CLIENT_SUPPORT_FILE))

    warnings = []
    properties = []

    # Get a list off CSS properties
    @processed_doc.search("*[@style]").each do |el|
      style_url = el.attributes['style'].to_s.gsub(/([\w\-]+)[\s]*\:/i) do |s|
        properties.push($1)
      end
    end

    properties.uniq!

    property_support = @client_support['css_properties']
    properties.each do |prop|
      if property_support.include?(prop) and
          property_support[prop].include?('support') and
          property_support[prop]['support'] >= @options[:warn_level]
        warnings.push({:message => "#{prop} CSS property",
            :level => WARN_LABEL[property_support[prop]['support']],
            :clients => property_support[prop]['unsupported_in'].join(', ')})
      end
    end

    @client_support['attributes'].each do |attribute, data|
      next unless data['support'] >= @options[:warn_level]
      if @doc.search("*[@#{attribute}]").length > 0
        warnings.push({:message => "#{attribute} HTML attribute",
            :level => WARN_LABEL[data['support']],
            :clients => data['unsupported_in'].join(', ')})
      end
    end

    @client_support['elements'].each do |element, data|
      next unless data['support'] >= @options[:warn_level]
      if @doc.search(element).length > 0
        warnings.push({:message => "#{element} HTML element",
            :level => WARN_LABEL[data['support']],
            :clients => data['unsupported_in'].join(', ')})
      end
    end

    return warnings
  end
end

