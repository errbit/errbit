#include "ruby_libxml.h"
#include "ruby_xml_xinclude.h"

VALUE cXMLXInclude;

/*
 * Document-class: LibXML::XML::XInclude
 *
 * The ruby bindings do not currently expose libxml's
 * XInclude fuctionality.
 */

void rxml_init_xinclude(void)
{
  cXMLXInclude = rb_define_class_under(mXML, "XInclude", rb_cObject);
}
