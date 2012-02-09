/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"
#include "ruby_xml_xpointer.h"

VALUE cXMLXPointer;

/*
 * Document-class: LibXML::XML::XPointer
 *
 * The XML::Pointer class provides a standards based API for searching an xml document.
 * XPointer is based on the XML Path Language (XML::XPath) and is documented
 * at http://www.w3.org/TR/WD-xptr.
 */

static VALUE rxml_xpointer_point(VALUE class, VALUE rnode, VALUE xptr_str)
{
#ifdef LIBXML_XPTR_ENABLED
  xmlNodePtr xnode;
  xmlXPathContextPtr xctxt;
  xmlXPathObjectPtr xpop;

  VALUE context;
  VALUE result;
  VALUE argv[1];

  Check_Type(xptr_str, T_STRING);
  if (rb_obj_is_kind_of(rnode, cXMLNode) == Qfalse)
  rb_raise(rb_eTypeError, "require an XML::Node object");

  Data_Get_Struct(rnode, xmlNode, xnode);

  argv[0] = rb_funcall(rnode, rb_intern("doc"), 0);
  context = rb_class_new_instance(1, argv, cXMLXPathContext);
  Data_Get_Struct(context, xmlXPathContext, xctxt);

  xpop = xmlXPtrEval((xmlChar*)StringValuePtr(xptr_str), xctxt);
  if (!xpop)
  rxml_raise(&xmlLastError);

  result = rxml_xpath_object_wrap(xnode->doc, xpop);
  rb_iv_set(result, "@context", context);

  return(result);
#else
  rb_warn("libxml was compiled without XPointer support");
  return (Qfalse);
#endif
}

VALUE rxml_xpointer_point2(VALUE node, VALUE xptr_str)
{
  return (rxml_xpointer_point(cXMLXPointer, node, xptr_str));
}

/*
 * call-seq:
 *    XML::XPointer.range(start_node, end_node) -> xpath
 *
 * Create an xpath representing the range between the supplied
 * start and end node.
 */
static VALUE rxml_xpointer_range(VALUE class, VALUE rstart, VALUE rend)
{
#ifdef LIBXML_XPTR_ENABLED
  xmlNodePtr start, end;
  VALUE rxxp;
  xmlXPathObjectPtr xpath;

  if (rb_obj_is_kind_of(rstart, cXMLNode) == Qfalse)
  rb_raise(rb_eTypeError, "require an XML::Node object as a starting point");
  if (rb_obj_is_kind_of(rend, cXMLNode) == Qfalse)
  rb_raise(rb_eTypeError, "require an XML::Node object as an ending point");

  Data_Get_Struct(rstart, xmlNode, start);
  if (start == NULL)
  return(Qnil);

  Data_Get_Struct(rend, xmlNode, end);
  if (end == NULL)
  return(Qnil);

  xpath = xmlXPtrNewRangeNodes(start, end);
  if (xpath == NULL)
  rb_fatal("You shouldn't be able to have this happen");

  rxxp = rxml_xpath_object_wrap(start->doc, xpath);
  return(rxxp);
#else
  rb_warn("libxml was compiled without XPointer support");
  return (Qfalse);
#endif
}

void rxml_init_xpointer(void)
{
  cXMLXPointer = rb_define_class_under(mXML, "XPointer", rb_cObject);
  rb_define_singleton_method(cXMLXPointer, "range", rxml_xpointer_range, 2);
}
