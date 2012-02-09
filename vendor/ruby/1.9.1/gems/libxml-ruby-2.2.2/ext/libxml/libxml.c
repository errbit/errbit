#include "ruby_libxml.h"

#if RUBY_INTERN_H
#include <ruby/util.h>
#else
#include <util.h>
#endif


VALUE mLibXML;

static void rxml_init_memory(void)
{
 /* Disable for now - broke attributes. 
  xmlGcMemSetup(
      (xmlFreeFunc)ruby_xfree,
      (xmlMallocFunc)ruby_xmalloc,
      (xmlMallocFunc)ruby_xmalloc,
      (xmlReallocFunc)ruby_xrealloc,
      (xmlStrdupFunc)ruby_strdup
  );*/
}

void Init_libxml_ruby(void)
{
/* The libxml gem provides Ruby language bindings for GNOME's Libxml2
 * XML toolkit.  To get started you may:
 *
 *  require 'test_helper'
 *  document = XML::Document.new
 *
 * However, when creating an application or library you plan to
 * redistribute, it is best to not add the LibXML module to the global
 * namespace, in which case you can either write your code like this:
 *
 *  require 'libxml'
 *  document = LibXML::XML::Document.new
 *
 * Refer to the README file to get started and the LICENSE file for
 * copyright and distribution information.
 */
  mLibXML = rb_define_module("LibXML");

  rxml_init_memory();
  rxml_init_xml();
  rxml_init_io();
  rxml_init_error();
  rxml_init_encoding();
  rxml_init_parser();
  rxml_init_parser_context();
  rxml_init_parser_options();
  rxml_init_node();
  rxml_init_attributes();
  rxml_init_attr();
  rxml_init_attr_decl();
  rxml_init_document();
  rxml_init_namespaces();
  rxml_init_namespace();
  rxml_init_sax_parser();
  rxml_init_sax2_handler();
  rxml_init_xinclude();
  rxml_init_xpath();
  rxml_init_xpath_object();
  rxml_init_xpath_context();
  rxml_init_xpath_expression();
  rxml_init_xpointer();
  rxml_init_html_parser();
  rxml_init_html_parser_options();
  rxml_init_html_parser_context();
  rxml_init_input_callbacks();
  rxml_init_dtd();
  rxml_init_schema();
  rxml_init_relaxng();
  rxml_init_reader();
}
