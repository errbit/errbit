/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"

/* Document-class: LibXML::XML::HTMLParser
 *
 * The HTML parser implements an HTML 4.0 non-verifying parser with an API
 * compatible with the XML::Parser.  In contrast with the XML::Parser,
 * it can parse "real world" HTML, even if it severely broken from a
 * specification point of view.
 *
 * The HTML parser creates an in-memory document object
 * that consist of any number of XML::Node instances.  This is simple
 * and powerful model, but has the major limitation that the size of
 * the document that can be processed is limited by the amount of
 * memory available.
 *
 * Using the html parser is simple:
 *
 *   parser = XML::HTMLParser.file('my_file')
 *   doc = parser.parse
 *
 * You can also parse documents (see XML::HTMLParser.document), 
 * strings (see XML::HTMLParser.string) and io objects (see
 * XML::HTMLParser.io).
 */

VALUE cXMLHtmlParser;
static ID CONTEXT_ATTR;


/* call-seq:
 *    XML::HTMLParser.initialize -> parser
 *
 * Initializes a new parser instance with no pre-determined source.
 */
static VALUE rxml_html_parser_initialize(int argc, VALUE *argv, VALUE self)
{
  VALUE context = Qnil;

  rb_scan_args(argc, argv, "01", &context);

  if (context == Qnil)
  {
    rb_warn("Passing no parameters to XML::HTMLParser.new is deprecated.  Pass an instance of XML::Parser::Context instead.");
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
static VALUE rxml_html_parser_parse(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  VALUE context = rb_ivar_get(self, CONTEXT_ATTR);
  
  Data_Get_Struct(context, xmlParserCtxt, ctxt);

  if (htmlParseDocument(ctxt) == -1 && ! ctxt->recovery)
  {
    if (ctxt->myDoc)
      xmlFreeDoc(ctxt->myDoc);
    rxml_raise(&ctxt->lastError);
  }

  rb_funcall(context, rb_intern("close"), 0);

  return rxml_document_wrap(ctxt->myDoc);
}

void rxml_init_html_parser(void)
{
  CONTEXT_ATTR = rb_intern("@context");

  cXMLHtmlParser = rb_define_class_under(mXML, "HTMLParser", rb_cObject);

  /* Atributes */
  rb_define_attr(cXMLHtmlParser, "input", 1, 0);

  /* Instance methods */
  rb_define_method(cXMLHtmlParser, "initialize", rxml_html_parser_initialize, -1);
  rb_define_method(cXMLHtmlParser, "parse", rxml_html_parser_parse, 0);
}
