module CssParser
  # Exception class used for any errors encountered while downloading remote files.
  class RemoteFileError < IOError; end

  # Exception class used if a request is made to load a CSS file more than once.
  class CircularReferenceError < StandardError; end


  # == Parser class
  #
  # All CSS is converted to UTF-8.
  #
  # When calling Parser#new there are some configuaration options:
  # [<tt>absolute_paths</tt>] Convert relative paths to absolute paths (<tt>href</tt>, <tt>src</tt> and <tt>url('')</tt>. Boolean, default is <tt>false</tt>.
  # [<tt>import</tt>] Follow <tt>@import</tt> rules. Boolean, default is <tt>true</tt>.
  # [<tt>io_exceptions</tt>] Throw an exception if a link can not be found. Boolean, default is <tt>true</tt>.
  class Parser
    USER_AGENT   = "Ruby CSS Parser/#{CssParser::VERSION} (http://github.com/alexdunae/css_parser)"

    STRIP_CSS_COMMENTS_RX = /\/\*.*?\*\//m
    STRIP_HTML_COMMENTS_RX = /\<\!\-\-|\-\-\>/m

    # Initial parsing
    RE_AT_IMPORT_RULE = /\@import\s*(?:url\s*)?(?:\()?(?:\s*)["']?([^'"\s\)]*)["']?\)?([\w\s\,^\]\(\))]*)\)?[;\n]?/

     # Array of CSS files that have been loaded.
    attr_reader   :loaded_uris
    
    #--
    # Class variable? see http://www.oreillynet.com/ruby/blog/2007/01/nubygems_dont_use_class_variab_1.html
    #++
    @folded_declaration_cache = {}
    class << self; attr_reader :folded_declaration_cache; end

    def initialize(options = {})
      @options = {:absolute_paths => false,
                  :import => true,
                  :io_exceptions => true}.merge(options)

      # array of RuleSets
      @rules = []
    
      
      @loaded_uris = []
    
      # unprocessed blocks of CSS
      @blocks = []
      reset!
    end

    # Get declarations by selector.
    #
    # +media_types+ are optional, and can be a symbol or an array of symbols.
    # The default value is <tt>:all</tt>.
    #
    # ==== Examples
    #  find_by_selector('#content')
    #  => 'font-size: 13px; line-height: 1.2;'
    #
    #  find_by_selector('#content', [:screen, :handheld])
    #  => 'font-size: 13px; line-height: 1.2;'
    #
    #  find_by_selector('#content', :print)
    #  => 'font-size: 11pt; line-height: 1.2;'
    #
    # Returns an array of declarations.
    def find_by_selector(selector, media_types = :all)
      out = []
      each_selector(media_types) do |sel, dec, spec|
        out << dec if sel.strip == selector.strip
      end
      out
    end
    alias_method :[], :find_by_selector


    # Add a raw block of CSS.
    #
    # In order to follow +@import+ rules you must supply either a
    # +:base_dir+ or +:base_uri+ option.
    #
    # Use the +:media_types+ option to set the media type(s) for this block.  Takes an array of symbols.
    #
    # Use the +:only_media_types+ option to selectively follow +@import+ rules.  Takes an array of symbols.
    #
    # ==== Example
    #   css = <<-EOT
    #     body { font-size: 10pt }
    #     p { margin: 0px; }
    #     @media screen, print {
    #       body { line-height: 1.2 }
    #     }
    #   EOT
    #
    #   parser = CssParser::Parser.new
    #   parser.add_block!(css)
    def add_block!(block, options = {})
      options = {:base_uri => nil, :base_dir => nil, :charset => nil, :media_types => :all, :only_media_types => :all}.merge(options)
      options[:media_types] = [options[:media_types]].flatten.collect { |mt| CssParser.sanitize_media_query(mt)}
      options[:only_media_types] = [options[:only_media_types]].flatten.collect { |mt| CssParser.sanitize_media_query(mt)}

      block = cleanup_block(block)

      if options[:base_uri] and @options[:absolute_paths]
        block = CssParser.convert_uris(block, options[:base_uri])
      end
      
      # Load @imported CSS
      block.scan(RE_AT_IMPORT_RULE).each do |import_rule|
        media_types = []
        if media_string = import_rule[-1]
          media_string.split(/[,]/).each do |t|
            media_types << CssParser.sanitize_media_query(t) unless t.empty?
          end
        else
          media_types = [:all]
        end
        
        next unless options[:only_media_types].include?(:all) or media_types.length < 1 or (media_types & options[:only_media_types]).length > 0

        import_path = import_rule[0].to_s.gsub(/['"]*/, '').strip

        if options[:base_uri]
          import_uri = Addressable::URI.parse(options[:base_uri].to_s) + Addressable::URI.parse(import_path)
          load_uri!(import_uri, options[:base_uri], media_types)
        elsif options[:base_dir]
          load_file!(import_path, options[:base_dir], media_types)
        end     
      end

      # Remove @import declarations
      block.gsub!(RE_AT_IMPORT_RULE, '')
      
      parse_block_into_rule_sets!(block, options)
    end

    # Add a CSS rule by setting the +selectors+, +declarations+ and +media_types+.
    #
    # +media_types+ can be a symbol or an array of symbols.
    def add_rule!(selectors, declarations, media_types = :all)
      rule_set = RuleSet.new(selectors, declarations)
      add_rule_set!(rule_set, media_types)
    end

    # Add a CssParser RuleSet object.
    #
    # +media_types+ can be a symbol or an array of symbols.
    def add_rule_set!(ruleset, media_types = :all)
      raise ArgumentError unless ruleset.kind_of?(CssParser::RuleSet)

      media_types = [media_types].flatten.collect { |mt| CssParser.sanitize_media_query(mt)}

      @rules << {:media_types => media_types, :rules => ruleset}
    end

    # Iterate through RuleSet objects.
    #
    # +media_types+ can be a symbol or an array of symbols.
    def each_rule_set(media_types = :all) # :yields: rule_set
      media_types = [:all] if media_types.nil?
      media_types = [media_types].flatten.collect { |mt| CssParser.sanitize_media_query(mt)}

      @rules.each do |block|
        if media_types.include?(:all) or block[:media_types].any? { |mt| media_types.include?(mt) }
          yield block[:rules]
        end
      end
    end

    # Iterate through CSS selectors.
    #
    # +media_types+ can be a symbol or an array of symbols.
    # See RuleSet#each_selector for +options+.
    def each_selector(media_types = :all, options = {}) # :yields: selectors, declarations, specificity
      each_rule_set(media_types) do |rule_set|
        rule_set.each_selector(options) do |selectors, declarations, specificity|
          yield selectors, declarations, specificity
        end
      end
    end

    # Output all CSS rules as a single stylesheet.
    def to_s(media_types = :all)
      out = ''
      each_selector(media_types) do |selectors, declarations, specificity|
        out << "#{selectors} {\n#{declarations}\n}\n"
      end
      out
    end
    
    # A hash of { :media_query => rule_sets }
    def rules_by_media_query
      rules_by_media = {}
      @rules.each do |block|
        block[:media_types].each do |mt|
          unless rules_by_media.has_key?(mt)
            rules_by_media[mt] = []
          end
          rules_by_media[mt] << block[:rules]
        end
      end
      
      rules_by_media
    end

    # Merge declarations with the same selector.
    def compact! # :nodoc:
      compacted = []

      compacted
    end

    def parse_block_into_rule_sets!(block, options = {}) # :nodoc:
      current_media_queries = [:all]
      if options[:media_types]
        current_media_queries = options[:media_types].flatten.collect { |mt| CssParser.sanitize_media_query(mt)}
      end

      in_declarations = 0
      block_depth = 0

      in_charset = false # @charset is ignored for now
      in_string = false
      in_at_media_rule = false
      in_media_block = false

      current_selectors = ''
      current_media_query = ''
      current_declarations = ''

      block.scan(/([\\]?[{}\s"]|(.[^\s"{}\\]*))/).each do |matches|
        token = matches[0]

        if token =~ /\A"/ # found un-escaped double quote
          in_string = !in_string
        end       

        if in_declarations > 0
          # too deep, malformed declaration block
          if in_declarations > 1
            in_declarations -= 1 if token =~ /\}/
            next
          end
          
          if token =~ /\{/
            in_declarations += 1
            next
          end
        
          current_declarations += token

          if token =~ /\}/ and not in_string
            current_declarations.gsub!(/\}[\s]*$/, '')
            
            in_declarations -= 1

            unless current_declarations.strip.empty?
              add_rule!(current_selectors, current_declarations, current_media_queries)
            end

            current_selectors = ''
            current_declarations = ''
          end
        elsif token =~ /@media/i
          # found '@media', reset current media_types
          in_at_media_rule = true
          media_types = []
        elsif in_at_media_rule
          if token =~ /\{/
            block_depth = block_depth + 1
            in_at_media_rule = false
            in_media_block = true
            current_media_queries << CssParser.sanitize_media_query(current_media_query)
            current_media_query = ''
          elsif token =~ /[,]/
            # new media query begins
            token.gsub!(/[,]/, ' ')
            current_media_query += token.strip + ' '
            current_media_queries << CssParser.sanitize_media_query(current_media_query)
            current_media_query = ''
          else
            current_media_query += token.strip + ' '
          end
        elsif in_charset or token =~ /@charset/i
          # iterate until we are out of the charset declaration
          in_charset = (token =~ /;/ ? false : true)
        else
          if token =~ /\}/ and not in_string
            block_depth = block_depth - 1

            # reset the current media query scope
            if in_media_block
              current_media_queries = []
              in_media_block = false
            end
          else
            if token =~ /\{/ and not in_string
              current_selectors.gsub!(/^[\s]*/, '')
              current_selectors.gsub!(/[\s]*$/, '')
              in_declarations += 1
            else
              current_selectors += token
            end
          end
        end
      end

      # check for unclosed braces          
      if in_declarations > 0
        add_rule!(current_selectors, current_declarations, current_media_queries)
      end
    end

    # Load a remote CSS file.
    #
    # You can also pass in file://test.css
    #
    # See add_block! for options.
    #
    # Deprecated: originally accepted three params: `uri`, `base_uri` and `media_types`
    def load_uri!(uri, options = {}, deprecated = nil)
      uri = Addressable::URI.parse(uri) unless uri.respond_to? :scheme
      #base_uri = nil, media_types = :all, options = {}

      opts = {:base_uri => nil, :media_types => :all}

      if options.is_a? Hash
        opts.merge!(options)
      else
        opts[:base_uri] = options if options.is_a? String
        opts[:media_types] = deprecated if deprecated
      end
      
      
      if uri.scheme == 'file' or uri.scheme.nil?
        uri.path = File.expand_path(uri.path)
        uri.scheme = 'file'
      end

      opts[:base_uri] = uri if opts[:base_uri].nil?

      src, charset = read_remote_file(uri)

      if src
        add_block!(src, opts)
      end
    end
    
    # Load a local CSS file.
    def load_file!(file_name, base_dir = nil, media_types = :all)
      file_name = File.expand_path(file_name, base_dir)
      return unless File.readable?(file_name)
      return unless circular_reference_check(file_name)

      src = IO.read(file_name)
      base_dir = File.dirname(file_name)

      add_block!(src, {:media_types => media_types, :base_dir => base_dir})
    end
    
    

  protected
    # Check that a path hasn't been loaded already
    #
    # Raises a CircularReferenceError exception if io_exceptions are on, 
    # otherwise returns true/false.
    def circular_reference_check(path)
      path = path.to_s
      if @loaded_uris.include?(path)
        raise CircularReferenceError, "can't load #{path} more than once" if @options[:io_exceptions]
        return false
      else
        @loaded_uris << path
        return true
      end
    end
  
    # Strip comments and clean up blank lines from a block of CSS.
    #
    # Returns a string.
    def cleanup_block(block) # :nodoc:
      # Strip CSS comments
      block.gsub!(STRIP_CSS_COMMENTS_RX, '')

      # Strip HTML comments - they shouldn't really be in here but 
      # some people are just crazy...
      block.gsub!(STRIP_HTML_COMMENTS_RX, '')

      # Strip lines containing just whitespace
      block.gsub!(/^\s+$/, "")

      block
    end

    # Download a file into a string.
    #
    # Returns the file's data and character set in an array.
    #--
    # TODO: add option to fail silently or throw and exception on a 404
    #++
    def read_remote_file(uri) # :nodoc:
      return nil, nil unless circular_reference_check(uri.to_s)    

      src = '', charset = nil

      begin
        uri = Addressable::URI.parse(uri.to_s)          

        if uri.scheme == 'file'
          # local file
          fh = open(uri.path, 'rb')
          src = fh.read
          fh.close
        else
          # remote file
          if uri.scheme == 'https'
            uri.port = 443 unless uri.port
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true 
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          else
            http = Net::HTTP.new(uri.host, uri.port)
          end

          res, src = http.get(uri.path, {'User-Agent' => USER_AGENT, 'Accept-Encoding' => 'gzip'})
          charset = fh.respond_to?(:charset) ? fh.charset : 'utf-8'

          if res.code.to_i >= 400
            raise RemoteFileError if @options[:io_exceptions]
            return '', nil
          end

          case res['content-encoding']
            when 'gzip'
              io = Zlib::GzipReader.new(StringIO.new(res.body))
              src = io.read
            when 'deflate'
              io = Zlib::Inflate.new
              src = io.inflate(res.body)
          end
        end

        if charset
          ic = Iconv.new('UTF-8//IGNORE', charset)
          src = ic.iconv(src)
        end
      rescue
        raise RemoteFileError if @options[:io_exceptions]
        return nil, nil
      end

      return src, charset  
    end

  private
    # Save a folded declaration block to the internal cache.
    def save_folded_declaration(block_hash, folded_declaration) # :nodoc:
      @folded_declaration_cache[block_hash] = folded_declaration
    end

    # Retrieve a folded declaration block from the internal cache.
    def get_folded_declaration(block_hash) # :nodoc:
      return @folded_declaration_cache[block_hash] ||= nil
    end

    def reset! # :nodoc:
      @folded_declaration_cache = {}
      @css_source = ''
      @css_rules = []
      @css_warnings = []
    end
  end
end
