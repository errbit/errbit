/* Please see the LICENSE file for copyright and distribution information */

#include <stdarg.h>
#include "ruby_libxml.h"

/* Document-class: LibXML::XML::Parser::Options
 *
 * Options that control the operation of the HTMLParser.  The easiest
 * way to set a parser's options is to use the methods
 * XML::Parser.file, XML::Parser.io or XML::Parser.string.
 * For additional control, see XML::Parser::Context#options=.
*/

VALUE mXMLParserOptions;

void rxml_init_parser_options(void)
{
  mXMLParserOptions = rb_define_module_under(cXMLParser, "Options");

  /* recover on errors */  
  rb_define_const(mXMLParserOptions, "RECOVER", INT2NUM(XML_PARSE_RECOVER));
  /* substitute entities */
  rb_define_const(mXMLParserOptions, "NOENT", INT2NUM(XML_PARSE_NOENT));
  /* load the external subset */
  rb_define_const(mXMLParserOptions, "DTDLOAD", INT2NUM(XML_PARSE_DTDLOAD));
  /* default DTD attributes */
  rb_define_const(mXMLParserOptions, "DTDATTR", INT2NUM(XML_PARSE_DTDATTR));
  /* validate with the DTD */
  rb_define_const(mXMLParserOptions, "DTDVALID", INT2NUM(XML_PARSE_DTDVALID));
  /* suppress error reports */
  rb_define_const(mXMLParserOptions, "NOERROR", INT2NUM(XML_PARSE_NOERROR));
  /* suppress warning reports */
  rb_define_const(mXMLParserOptions, "NOWARNING", INT2NUM(XML_PARSE_NOWARNING));
  /* pedantic error reporting */
  rb_define_const(mXMLParserOptions, "PEDANTIC", INT2NUM(XML_PARSE_PEDANTIC));
  /* remove blank nodes */
  rb_define_const(mXMLParserOptions, "NOBLANKS", INT2NUM(XML_PARSE_NOBLANKS));
  /* use the SAX1 interface internally */
  rb_define_const(mXMLParserOptions, "SAX1", INT2NUM(XML_PARSE_SAX1));
  /* Implement XInclude substitition  */
  rb_define_const(mXMLParserOptions, "XINCLUDE", INT2NUM(XML_PARSE_XINCLUDE));
  /* Forbid network access */
  rb_define_const(mXMLParserOptions, "NONET", INT2NUM(XML_PARSE_NONET));
  /* Do not reuse the context dictionnary */
  rb_define_const(mXMLParserOptions, "NODICT", INT2NUM(XML_PARSE_NODICT));
  /* remove redundant namespaces declarations */
  rb_define_const(mXMLParserOptions, "NSCLEAN", INT2NUM(XML_PARSE_NSCLEAN));
  /* merge CDATA as text nodes */
  rb_define_const(mXMLParserOptions, "NOCDATA", INT2NUM(XML_PARSE_NOCDATA));
#if LIBXML_VERSION >= 20621
  /* do not generate XINCLUDE START/END nodes */
  rb_define_const(mXMLParserOptions, "NOXINCNODE", INT2NUM(XML_PARSE_NOXINCNODE));
#endif
#if LIBXML_VERSION >= 20700
  /* compact small text nodes */
  rb_define_const(mXMLParserOptions, "COMPACT", INT2NUM(XML_PARSE_COMPACT));
  /* parse using XML-1.0 before update 5 */
  rb_define_const(mXMLParserOptions, "PARSE_OLD10", INT2NUM(XML_PARSE_OLD10));
  /* do not fixup XINCLUDE xml:base uris */
  rb_define_const(mXMLParserOptions, "NOBASEFIX", INT2NUM(XML_PARSE_NOBASEFIX));
#endif
#if LIBXML_VERSION >= 20703
  /* relax any hardcoded limit from the parser */
  rb_define_const(mXMLParserOptions, "HUGE", INT2NUM(XML_PARSE_HUGE));
#endif
}
