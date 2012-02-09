/* Please see the LICENSE file for copyright and distribution information */

#include <stdarg.h>
#include "ruby_libxml.h"

/*
 * Document-class: LibXML::XML::Parser
 *
 * The XML::Parser provides a tree based API for processing
 * xml documents, in contract to XML::Reader's stream
 * based api and XML::SaxParser callback based API.
 *
 * As a result, parsing a document creates an in-memory document object
 * that consist of any number of XML::Node instances.  This is simple
 * and powerful model, but has the major limitation that the size of
 * the document that can be processed is limited by the amount of
 * memory available.  In such cases, it is better to use the XML::Reader.
 *
 * Using the parser is simple:
 *
 *   parser = XML::Parser.file('my_file')
 *   doc = parser.parse
 *
 * You can also parse documents (see XML::Parser.document), 
 * strings (see XML::Parser.string) and io objects (see
 * XML::Parser.io).
 */

VALUE cXMLParser;
static ID CONTEXT_ATTR;

/*
 * call-seq:
 *    parser.initialize(context) -> XML::Parser
 *
 * Creates a new XML::Parser from the specified 
 * XML::Parser::Context.
 */
static VALUE rxml_parser_initialize(int argc, VALUE *argv, VALUE self)
{
  VALUE context = Qnil;

  rb_scan_args(argc, argv, "01", &context);

  if (context == Qnil)
  {
    rb_warn("Passing no parameters to XML::Parser.new is deprecated.  Pass an instance of XML::Parser::Context instead.");
    context = rb_class_new_instance(0, NULL, cXMLParserContext);
  }

  rb_ivar_set(self, CONTEXT_ATTR, context);
  return self;
}

/*
 * call-seq:
 *    parser.parse -> XML::Document
 *
 * Parse the input XML and create an XML::Document with
 * it's content. If an error occurs, XML::Parser::ParseError
 * is thrown.
 */
static VALUE rxml_parser_parse(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  VALUE context = rb_ivar_get(self, CONTEXT_ATTR);
  
  Data_Get_Struct(context, xmlParserCtxt, ctxt);

  if ((xmlParseDocument(ctxt) == -1 || !ctxt->wellFormed) && ! ctxt->recovery)
  {
    if (ctxt->myDoc)
      xmlFreeDoc(ctxt->myDoc);
    rxml_raise(&ctxt->lastError);
  }

  rb_funcall(context, rb_intern("close"), 0);

  return rxml_document_wrap(ctxt->myDoc);
}

void rxml_init_parser(void)
{
  cXMLParser = rb_define_class_under(mXML, "Parser", rb_cObject);

  /* Atributes */
  CONTEXT_ATTR = rb_intern("@context");
  rb_define_attr(cXMLParser, "input", 1, 0);
  rb_define_attr(cXMLParser, "context", 1, 0);

  /* Instance Methods */
  rb_define_method(cXMLParser, "initialize", rxml_parser_initialize, -1);
  rb_define_method(cXMLParser, "parse", rxml_parser_parse, 0);
}
