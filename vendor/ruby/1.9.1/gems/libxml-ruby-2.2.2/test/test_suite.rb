# encoding: UTF-8

# Change to current directory so relative
# requires work.
dir = File.dirname(__FILE__)
Dir.chdir(dir)

require './tc_attr'
require './tc_attr_decl'
require './tc_attributes'
require './tc_document'
require './tc_document_write'
require './tc_dtd'
require './tc_encoding'
require './tc_error'
require './tc_html_parser'
require './tc_html_parser_context'
require './tc_namespace'
require './tc_namespaces'
require './tc_node'
require './tc_node_cdata'
require './tc_node_comment'
require './tc_node_copy'
require './tc_node_edit'
require './tc_node_text'
require './tc_node_write'
require './tc_node_xlink'
require './tc_parser'
require './tc_parser_context'
require './tc_reader'
require './tc_relaxng'
require './tc_sax_parser'
require './tc_schema'
require './tc_traversal'
require './tc_xinclude'
require './tc_xpath'
require './tc_xpath_context'
require './tc_xpath_expression'
require './tc_xpointer'

# Compatibility
require './tc_properties'
require './tc_deprecated_require'