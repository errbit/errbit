# encoding: UTF-8

module LibXML
  module XML
    class Parser
      # call-seq:
      #    XML::Parser.document(document) -> XML::Parser
      #
      # Creates a new parser for the specified document.
      #
      # Parameters:
      #
      #  document - A preparsed document.
      def self.document(doc)
        context = XML::Parser::Context.document(doc)
        self.new(context)
      end

      # call-seq:
      #    XML::Parser.file(path) -> XML::Parser
      #    XML::Parser.file(path, :encoding => XML::Encoding::UTF_8,
      #                           :options => XML::Parser::Options::NOENT) -> XML::Parser
      #
      # Creates a new parser for the specified file or uri.
      #
      # You may provide an optional hash table to control how the
      # parsing is performed.  Valid options are:
      #
      #  encoding - The document encoding, defaults to nil. Valid values
      #             are the encoding constants defined on XML::Encoding.
      #  options - Parser options.  Valid values are the constants defined on
      #            XML::Parser::Options.  Mutliple options can be combined
      #            by using Bitwise OR (|).
      def self.file(path, options = {})
        context = XML::Parser::Context.file(path)
        context.encoding = options[:encoding] if options[:encoding]
        context.options = options[:options] if options[:options]
        self.new(context)
      end

      # call-seq:
      #    XML::Parser.io(io) -> XML::Parser
      #    XML::Parser.io(io, :encoding => XML::Encoding::UTF_8,
      #                       :options => XML::Parser::Options::NOENT
      #                       :base_uri="http://libxml.org") -> XML::Parser
      #
      # Creates a new parser for the specified io object.
      #
      # Parameters:
      #
      #  io - io object that contains the xml to parser
      #  base_uri - The base url for the parsed document.
      #  encoding - The document encoding, defaults to nil. Valid values
      #             are the encoding constants defined on XML::Encoding.
      #  options - Parser options.  Valid values are the constants defined on
      #            XML::Parser::Options.  Mutliple options can be combined
      #            by using Bitwise OR (|).
      def self.io(io, options = {})
        context = XML::Parser::Context.io(io)
        context.base_uri = options[:base_uri] if options[:base_uri]
        context.encoding = options[:encoding] if options[:encoding]
        context.options = options[:options] if options[:options]
        self.new(context)
      end

      # call-seq:
      #    XML::Parser.string(string)
      #    XML::Parser.string(string, :encoding => XML::Encoding::UTF_8,
      #                               :options => XML::Parser::Options::NOENT
      #                               :base_uri="http://libxml.org") -> XML::Parser
      #
      # Creates a new parser by parsing the specified string.
      #
      # You may provide an optional hash table to control how the
      # parsing is performed.  Valid options are:
      #
      #  base_uri - The base url for the parsed document.
      #  encoding - The document encoding, defaults to nil. Valid values
      #             are the encoding constants defined on XML::Encoding.
      #  options - Parser options.  Valid values are the constants defined on
      #            XML::Parser::Options.  Mutliple options can be combined
      #            by using Bitwise OR (|).
      def self.string(string, options = {})
        context = XML::Parser::Context.string(string)
        context.base_uri = options[:base_uri] if options[:base_uri]
        context.encoding = options[:encoding] if options[:encoding]
        context.options = options[:options] if options[:options]
        self.new(context)
      end

      def self.register_error_handler(proc)
        warn('Parser.register_error_handler is deprecated.  Use Error.set_handler instead')
        if proc.nil?
          Error.reset_handler
        else
          Error.set_handler(&proc)
        end
      end

      # :enddoc:

      # Bunch of deprecated methods that have moved to the XML module
      VERSION = XML::VERSION
      VERNUM = XML::VERNUM

      def document=(value)
        warn("XML::Parser#document= is deprecated.  Use XML::Parser.document= instead")
        @context = XML::Parser::Context.document(value)
      end

      def file=(value)
        warn("XML::Parser#file is deprecated.  Use XML::Parser.file instead")
        @context = XML::Parser::Context.file(value)
      end

      def filename=(value)
        warn("XML::Parser#filename is deprecated.  Use XML::Parser.file instead")
        self.file = value
      end

      def io=(value)
        warn("XML::Parser#io is deprecated.  Use XML::Parser.io instead")
        @context = XML::Parser::Context.io(value)
      end

      def string=(value)
        warn("XML::Parser#string is deprecated.  Use XML::Parser.string instead")
        @context = XML::Parser::Context.string(value)
      end

      def self.enabled_automata?
        warn("XML::Parser.enabled_automata? has been deprecated.  Use XML.enabled_automata? instead")
        XML.enabled_automata?
      end

      def self.enabled_c14n?
        warn("XML::Parser.enabled_c14n? has been deprecated.  Use XML.enabled_c14n? instead")
        XML.enabled_c14n?
      end

      def self.enabled_catalog?
        warn("XML::Parser.enabled_catalog? has been deprecated.  Use XML.enabled_catalog? instead")
        XML.enabled_catalog?
      end

      def self.enabled_debug?
        warn("XML::Parser.enabled_debug? has been deprecated.  Use XML.enabled_debug? instead")
        XML.enabled_debug?
      end

      def self.enabled_docbook?
        warn("XML::Parser.enabled_docbook? has been deprecated.  Use XML.enabled_docbook? instead")
        XML.enabled_docbook?
      end

      def self.enabled_ftp?
        warn("XML::Parser.enabled_ftp? has been deprecated.  Use XML.enabled_ftp? instead")
        XML.enabled_ftp?
      end

      def self.enabled_http?
        warn("XML::Parser.enabled_http? has been deprecated.  Use XML.enabled_http? instead")
        XML.enabled_http?
      end

      def self.enabled_html?
        warn("XML::Parser.enabled_html? has been deprecated.  Use XML.enabled_html? instead")
        XML.enabled_html?
      end

      def self.enabled_iconv?
        warn("XML::Parser.enabled_iconv? has been deprecated.  Use XML.enabled_iconv? instead")
        XML.enabled_iconv?
      end

      def self.enabled_memory_debug?
        warn("XML::Parser.enabled_memory_debug_location? has been deprecated.  Use XML.enabled_memory_debug_location? instead")
        XML.enabled_memory_debug_location?
      end

      def self.enabled_regexp?
        warn("XML::Parser.enabled_regexp? has been deprecated.  Use XML.enabled_regexp? instead")
        XML.enabled_regexp?
      end

      def self.enabled_schemas?
        warn("XML::Parser.enabled_schemas? has been deprecated.  Use XML.enabled_schemas? instead")
        XML.enabled_schemas?
      end

      def self.enabled_thread?
        warn("XML::Parser.enabled_thread? has been deprecated.  Use XML.enabled_thread? instead")
        XML.enabled_thread?
      end

      def self.enabled_unicode?
        warn("XML::Parser.enabled_unicode? has been deprecated.  Use XML.enabled_unicode? instead")
        XML.enabled_unicode?
      end

      def self.enabled_xinclude?
        warn("XML::Parser.enabled_xinclude? has been deprecated.  Use XML.enabled_xinclude? instead")
        XML.enabled_xinclude?
      end

      def self.enabled_xpath?
        warn("XML::Parser.enabled_xpath? has been deprecated.  Use XML.enabled_xpath? instead")
        XML.enabled_xpath?
      end

      def self.enabled_xpointer?
        warn("XML::Parser.enabled_xpointer? has been deprecated.  Use XML.enabled_xpointer? instead")
        XML.enabled_xpointer?
      end

      def self.enabled_zlib?
        warn("XML::Parser.enabled_zlib? has been deprecated.  Use XML.enabled_zlib? instead")
        XML.enabled_zlib?
      end

      def self.catalog_dump
        warn("XML::Parser.catalog_dump has been deprecated.  Use XML.catalog_dump instead")
        XML.catalog_dump
      end

      def self.catalog_remove
        warn("XML::Parser.catalog_remove has been deprecated.  Use XML.catalog_remove instead")
        XML.catalog_remove
      end

      def self.check_lib_versions
        warn("XML::Parser.check_lib_versions has been deprecated.  Use XML.check_lib_versions instead")
        XML.check_lib_versions
      end

      def self.debug_entities
        warn("XML::Parser.debug_entities has been deprecated.  Use XML.debug_entities instead")
        XML.debug_entities
      end

      def self.debug_entities=(value)
        warn("XML::Parser.debug_entities_set has been deprecated.  Use XML.debug_entities= value instead")
        XML.debug_entities= value
      end

      def self.default_compression
        warn("XML::Parser.default_compression has been deprecated.  Use XML.default_compression instead")
        XML.default_compression
      end

      def self.default_compression=(value)
        warn("XML::Parser.default_compression= value has been deprecated.  Use XML.default_compression= value instead")
        XML.default_compression= value
      end

      def self.default_keep_blanks
        warn("XML::Parser.default_keep_blanks has been deprecated.  Use XML.default_keep_blanks instead")
        XML.default_keep_blanks
      end

      def self.default_keep_blanks=(value)
        warn("XML::Parser.default_keep_blanks= value has been deprecated.  Use XML.default_keep_blanks= value instead")
        XML.default_keep_blanks= value
      end

      def self.default_load_external_dtd
        warn("XML::Parser.default_load_external_dtd has been deprecated.  Use XML.default_load_external_dtd instead")
        XML.default_load_external_dtd
      end

      def self.default_load_external_dtd=(value)
        warn("XML::Parser.default_load_external_dtd= value has been deprecated.  Use XML.default_load_external_dtd= value instead")
        XML.default_load_external_dtd= value
      end

      def self.default_line_numbers
        warn("XML::Parser.default_line_numbers has been deprecated.  Use XML.default_line_numbers instead")
        XML.default_line_numbers
      end

      def self.default_line_numbers=(value)
        warn("XML::Parser.default_line_numbers= value has been deprecated.  Use XML.default_line_numbers= value instead")
        XML.default_line_numbers= value
      end

      def self.default_pedantic_parser
        warn("XML::Parser.default_pedantic_parser has been deprecated.  Use XML.default_pedantic_parser instead")
        XML.default_pedantic_parser
      end

      def self.default_pedantic_parser=(value)
        warn("XML::Parser.default_pedantic_parser= value has been deprecated.  Use XML.default_pedantic_parser= value instead")
        XML.default_pedantic_parser= value
      end

      def self.default_substitute_entities
        warn("XML::Parser.default_substitute_entities has been deprecated.  Use XML.default_substitute_entities instead")
        XML.default_substitute_entities
      end

      def self.default_substitute_entities=(value)
        warn("XML::Parser.default_substitute_entities= value has been deprecated.  Use XML.default_substitute_entities= value instead")
        XML.default_substitute_entities= value
      end

      def self.default_tree_indent_string
        warn("XML::Parser.default_tree_indent_string has been deprecated.  Use XML.default_tree_indent_string instead")
        XML.default_tree_indent_string
      end

      def self.default_tree_indent_string=(value)
        warn("XML::Parser.default_tree_indent_string= value has been deprecated.  Use XML.default_tree_indent_string= value instead")
        XML.default_tree_indent_string= value
      end

      def self.default_validity_checking
        warn("XML::Parser.default_validity_checking has been deprecated.  Use XML.default_validity_checking instead")
        XML.default_validity_checking
      end

      def self.default_validity_checking=(value)
        warn("XML::Parser.default_validity_checking= value has been deprecated.  Use XML.default_validity_checking= value instead")
        XML.default_validity_checking= value
      end

      def self.default_warnings
        warn("XML::Parser.default_warnings has been deprecated.  Use XML.default_warnings instead")
        XML.default_warnings
      end

      def self.default_warnings=(value)
        warn("XML::Parser.default_warnings= value has been deprecated.  Use XML.default_warnings= value instead")
        XML.default_warnings= value
      end

      def self.features
        warn("XML::Parser.features has been deprecated.  Use XML.features instead")
        XML.features
      end

      def self.indent_tree_output
        warn("XML::Parser.indent_tree_output has been deprecated.  Use XML.indent_tree_output instead")
        XML.indent_tree_output
      end

      def self.indent_tree_output=(value)
        warn("XML::Parser.indent_tree_output= value has been deprecated.  Use XML.indent_tree_output= value instead")
        XML.indent_tree_output= value
      end

      def self.filename(value)
        warn("Parser.filename is deprecated.  Use Parser.file instead")
        self.file(value)
      end

      def self.memory_dump
        warn("XML::Parser.memory_dump has been deprecated.  Use XML.memory_dump instead")
        XML.memory_dump
      end

      def self.memory_used
        warn("XML::Parser.memory_used has been deprecated.  Use XML.memory_used instead")
        XML.memory_used
      end
    end
  end
end