# encoding: UTF-8

# Load the C-based binding.
begin
  RUBY_VERSION =~ /(\d+.\d+)/
  require "#{$1}/libxml_ruby"
rescue LoadError
  require "libxml_ruby"
end
# Load Ruby supporting code.
require 'libxml/error'
require 'libxml/parser'
require 'libxml/document'
require 'libxml/namespaces'
require 'libxml/namespace'
require 'libxml/node'
require 'libxml/ns'
require 'libxml/attributes'
require 'libxml/attr'
require 'libxml/attr_decl'
require 'libxml/tree'
require 'libxml/reader'
require 'libxml/html_parser'
require 'libxml/sax_parser'
require 'libxml/sax_callbacks'
require 'libxml/xpath_object'

# Deprecated
require 'libxml/properties'