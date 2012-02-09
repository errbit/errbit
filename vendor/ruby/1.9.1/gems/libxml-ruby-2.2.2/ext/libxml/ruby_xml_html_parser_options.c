/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"

/* Document-class: LibXML::XML::HTMLParser::Options
 *
 * Options to control the operation of the HTMLParser.  The easiest
 * way to set a parser's options is via the methods
 * XML::HTMLParser.file, XML::HTMLParser.io or XML::HTMLParser.string.
 * For additional control, see XML::HTMLParser::Context#options=.
*/

VALUE mXMLHtmlParserOptions;

void rxml_init_html_parser_options(void)
{
  mXMLHtmlParserOptions = rb_define_module_under(cXMLHtmlParser, "Options");


#if LIBXML_VERSION >= 20621
  /* 1: Relax parsing. */
  rb_define_const(mXMLHtmlParserOptions, "RECOVER", INT2NUM(HTML_PARSE_RECOVER)); 
#endif
#if LIBXML_VERSION >= 20708
  /* 2:  Do not default a doctype if not found */
  rb_define_const(mXMLHtmlParserOptions, "NODEFDTD", INT2NUM(HTML_PARSE_NODEFDTD));
#endif
  /* 32: Suppress error reports. */
  rb_define_const(mXMLHtmlParserOptions, "NOERROR", INT2NUM(HTML_PARSE_NOERROR)); 
  /* 64: Suppress warning reports. */
  rb_define_const(mXMLHtmlParserOptions, "NOWARNING", INT2NUM(HTML_PARSE_NOWARNING));
  /* 128: Enable pedantic error reporting. */
  rb_define_const(mXMLHtmlParserOptions, "PEDANTIC", INT2NUM(HTML_PARSE_PEDANTIC)); 
  /* 256: Remove blank nodes. */
  rb_define_const(mXMLHtmlParserOptions, "NOBLANKS", INT2NUM(HTML_PARSE_NOBLANKS)); 
#if LIBXML_VERSION >= 20621
  /* 2048: Forbid network access. */
  rb_define_const(mXMLHtmlParserOptions, "NONET", INT2NUM(HTML_PARSE_NONET)); 
  /* 65536: Compact small text nodes. */
  rb_define_const(mXMLHtmlParserOptions, "COMPACT", INT2NUM(HTML_PARSE_COMPACT));
#endif
#if LIBXML_VERSION >= 20707
  /* 8192:  Do not add implied html/body... elements */
  rb_define_const(mXMLHtmlParserOptions, "NOIMPLIED", INT2NUM(HTML_PARSE_NOIMPLIED));
#endif
}
