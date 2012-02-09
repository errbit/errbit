# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "nokogiri"
  s.version = "1.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Patterson", "Mike Dalessio", "Yoko Harada"]
  s.date = "2011-07-01"
  s.description = "Nokogiri (\u{e9}\u{8b}\u{b8}) is an HTML, XML, SAX, and Reader parser.  Among Nokogiri's\nmany features is the ability to search documents via XPath or CSS3 selectors.\n\nXML is like violence - if it doesn\u{e2}\u{80}\u{99}t solve your problems, you are not using\nenough of it."
  s.email = ["aaronp@rubyforge.org", "mike.dalessio@gmail.com", "yokolet@gmail.com"]
  s.executables = ["nokogiri"]
  s.extensions = ["ext/nokogiri/extconf.rb"]
  s.extra_rdoc_files = ["Manifest.txt", "README.ja.rdoc", "CHANGELOG.rdoc", "CHANGELOG.ja.rdoc", "README.rdoc", "ext/nokogiri/xml_sax_push_parser.c", "ext/nokogiri/xml_relax_ng.c", "ext/nokogiri/html_sax_parser_context.c", "ext/nokogiri/html_entity_lookup.c", "ext/nokogiri/xml_text.c", "ext/nokogiri/nokogiri.c", "ext/nokogiri/xml_element_decl.c", "ext/nokogiri/xml_encoding_handler.c", "ext/nokogiri/html_document.c", "ext/nokogiri/xslt_stylesheet.c", "ext/nokogiri/xml_attribute_decl.c", "ext/nokogiri/xml_io.c", "ext/nokogiri/xml_document_fragment.c", "ext/nokogiri/xml_namespace.c", "ext/nokogiri/xml_libxml2_hacks.c", "ext/nokogiri/xml_sax_parser_context.c", "ext/nokogiri/xml_comment.c", "ext/nokogiri/xml_sax_parser.c", "ext/nokogiri/html_element_description.c", "ext/nokogiri/xml_xpath_context.c", "ext/nokogiri/xml_syntax_error.c", "ext/nokogiri/xml_document.c", "ext/nokogiri/xml_entity_decl.c", "ext/nokogiri/xml_node.c", "ext/nokogiri/xml_node_set.c", "ext/nokogiri/xml_reader.c", "ext/nokogiri/xml_processing_instruction.c", "ext/nokogiri/xml_element_content.c", "ext/nokogiri/xml_dtd.c", "ext/nokogiri/xml_attr.c", "ext/nokogiri/xml_schema.c", "ext/nokogiri/xml_cdata.c", "ext/nokogiri/xml_entity_reference.c"]
  s.files = ["bin/nokogiri", "Manifest.txt", "README.ja.rdoc", "CHANGELOG.rdoc", "CHANGELOG.ja.rdoc", "README.rdoc", "ext/nokogiri/xml_sax_push_parser.c", "ext/nokogiri/xml_relax_ng.c", "ext/nokogiri/html_sax_parser_context.c", "ext/nokogiri/html_entity_lookup.c", "ext/nokogiri/xml_text.c", "ext/nokogiri/nokogiri.c", "ext/nokogiri/xml_element_decl.c", "ext/nokogiri/xml_encoding_handler.c", "ext/nokogiri/html_document.c", "ext/nokogiri/xslt_stylesheet.c", "ext/nokogiri/xml_attribute_decl.c", "ext/nokogiri/xml_io.c", "ext/nokogiri/xml_document_fragment.c", "ext/nokogiri/xml_namespace.c", "ext/nokogiri/xml_libxml2_hacks.c", "ext/nokogiri/xml_sax_parser_context.c", "ext/nokogiri/xml_comment.c", "ext/nokogiri/xml_sax_parser.c", "ext/nokogiri/html_element_description.c", "ext/nokogiri/xml_xpath_context.c", "ext/nokogiri/xml_syntax_error.c", "ext/nokogiri/xml_document.c", "ext/nokogiri/xml_entity_decl.c", "ext/nokogiri/xml_node.c", "ext/nokogiri/xml_node_set.c", "ext/nokogiri/xml_reader.c", "ext/nokogiri/xml_processing_instruction.c", "ext/nokogiri/xml_element_content.c", "ext/nokogiri/xml_dtd.c", "ext/nokogiri/xml_attr.c", "ext/nokogiri/xml_schema.c", "ext/nokogiri/xml_cdata.c", "ext/nokogiri/xml_entity_reference.c", "ext/nokogiri/extconf.rb"]
  s.homepage = "http://nokogiri.org"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubyforge_project = "nokogiri"
  s.rubygems_version = "1.8.15"
  s.summary = "Nokogiri (\u{e9}\u{8b}\u{b8}) is an HTML, XML, SAX, and Reader parser"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<racc>, [">= 1.4.6"])
      s.add_development_dependency(%q<rexical>, [">= 1.0.5"])
      s.add_development_dependency(%q<rake-compiler>, [">= 0.7.9"])
      s.add_development_dependency(%q<minitest>, ["~> 2.2.2"])
      s.add_development_dependency(%q<mini_portile>, [">= 0.2.2"])
      s.add_development_dependency(%q<hoe-debugging>, [">= 0"])
      s.add_development_dependency(%q<hoe-git>, [">= 0"])
      s.add_development_dependency(%q<hoe-gemspec>, [">= 0"])
      s.add_development_dependency(%q<hoe-bundler>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 2.9.4"])
    else
      s.add_dependency(%q<racc>, [">= 1.4.6"])
      s.add_dependency(%q<rexical>, [">= 1.0.5"])
      s.add_dependency(%q<rake-compiler>, [">= 0.7.9"])
      s.add_dependency(%q<minitest>, ["~> 2.2.2"])
      s.add_dependency(%q<mini_portile>, [">= 0.2.2"])
      s.add_dependency(%q<hoe-debugging>, [">= 0"])
      s.add_dependency(%q<hoe-git>, [">= 0"])
      s.add_dependency(%q<hoe-gemspec>, [">= 0"])
      s.add_dependency(%q<hoe-bundler>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 2.9.4"])
    end
  else
    s.add_dependency(%q<racc>, [">= 1.4.6"])
    s.add_dependency(%q<rexical>, [">= 1.0.5"])
    s.add_dependency(%q<rake-compiler>, [">= 0.7.9"])
    s.add_dependency(%q<minitest>, ["~> 2.2.2"])
    s.add_dependency(%q<mini_portile>, [">= 0.2.2"])
    s.add_dependency(%q<hoe-debugging>, [">= 0"])
    s.add_dependency(%q<hoe-git>, [">= 0"])
    s.add_dependency(%q<hoe-gemspec>, [">= 0"])
    s.add_dependency(%q<hoe-bundler>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 2.9.4"])
  end
end
