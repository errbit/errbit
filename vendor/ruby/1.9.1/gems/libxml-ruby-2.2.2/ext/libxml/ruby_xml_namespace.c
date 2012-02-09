/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"
#include "ruby_xml_namespace.h"

VALUE cXMLNamespace;

/* Document-class: LibXML::XML::Namespace
 *
 * The Namespace class represents an XML namespace.
 * To add a namespace to a node, create a new instance
 * of this class.  Note that this does *not* assign the
 * node to the namespace. To do that see the 
 * XML::Namespaces#namespace method.
 *
 * Usage:
 *
 *   node = XML::Node.new('<Envelope>')
 *   XML::Namespace.new(node, 'soap', 'http://schemas.xmlsoap.org/soap/envelope/')
 *   assert_equal("<Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"/>", node.to_s)
 *   assert_nil(node.namespaces.namespace)
 */

/* Namespaces are owned and freed by their nodes.  Thus, its easier for the
   ruby bindings to not manage attribute memory management. */

static VALUE rxml_namespace_alloc(VALUE klass)
{
  return Data_Wrap_Struct(klass, NULL, NULL, NULL);
}

VALUE rxml_namespace_wrap(xmlNsPtr xns)
{
  return Data_Wrap_Struct(cXMLNamespace, NULL, NULL, xns);
}


/*
 * call-seq:
 *    initialize(node, "prefix", "href") -> XML::Namespace
 *
 * Create a new namespace and adds it to the specified node.
 * Note this does *not* assign the node to the namespace.
 * To do that see the XML::Namespaces#namespace method.
 */
static VALUE rxml_namespace_initialize(VALUE self, VALUE node, VALUE prefix,
    VALUE href)
{
  xmlNodePtr xnode;
  xmlChar *xmlPrefix;
  xmlNsPtr xns;

  Check_Type(node, T_DATA);
  Data_Get_Struct(node, xmlNode, xnode);

  /* Prefix can be null - that means its the default namespace */
  xmlPrefix = NIL_P(prefix) ? NULL : (xmlChar *)StringValuePtr(prefix);
  xns = xmlNewNs(xnode, (xmlChar*) StringValuePtr(href), xmlPrefix);

  if (!xns)
    rxml_raise(&xmlLastError);

  DATA_PTR(self) = xns;
  return self;
}

/*
 * call-seq:
 *    ns.href -> "href"
 *
 * Usage:
 *
 *   doc = XML::Document.string('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"/>')
 *   ns = doc.root.namespaces.find_by_href('http://schemas.xmlsoap.org/soap/envelope/')
 *   assert_equal('http://schemas.xmlsoap.org/soap/envelope/', ns.href)
 */
static VALUE rxml_namespace_href_get(VALUE self)
{
  xmlNsPtr xns;
  Data_Get_Struct(self, xmlNs, xns);
  if (xns->href == NULL)
    return Qnil;
  else
    return rxml_new_cstr((const char*) xns->href, NULL);
}

/*
 * call-seq:
 *    ns.node_type -> num
 *
 * Obtain this namespace's type identifier.
 */
static VALUE rxml_namespace_node_type(VALUE self)
{
  xmlNsPtr xns;
  Data_Get_Struct(self, xmlNs, xns);
  return INT2NUM(xns->type);
}

/*
 * call-seq:
 *    ns.prefix -> "prefix"
 *
 * Obtain the namespace's prefix.
 *
 * Usage:
 *
 *   doc = XML::Document.string('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"/>')
 *   ns = doc.root.namespaces.find_by_href('http://schemas.xmlsoap.org/soap/envelope/')
 *   assert_equal('soap', ns.prefix)
 */
static VALUE rxml_namespace_prefix_get(VALUE self)
{
  xmlNsPtr xns;
  Data_Get_Struct(self, xmlNs, xns);
  if (xns->prefix == NULL)
    return Qnil;
  else
    return rxml_new_cstr((const char*) xns->prefix, NULL);
}

/*
 * call-seq:
 *    ns.next -> XML::Namespace
 *
 * Obtain the next namespace.
 *
 * Usage:
 *
 *   doc = XML::Document.string('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"/>')
 *   ns = doc.root.namespaces.find_by_href('http://schemas.xmlsoap.org/soap/envelope/')
 *   assert_nil(ns.next)
 */
static VALUE rxml_namespace_next(VALUE self)
{
  xmlNsPtr xns;
  Data_Get_Struct(self, xmlNs, xns);
  if (xns == NULL || xns->next == NULL)
    return (Qnil);
  else
    return rxml_namespace_wrap(xns->next);
}

void rxml_init_namespace(void)
{
  cXMLNamespace = rb_define_class_under(mXML, "Namespace", rb_cObject);
  rb_define_alloc_func(cXMLNamespace, rxml_namespace_alloc);
  rb_define_method(cXMLNamespace, "initialize", rxml_namespace_initialize, 3);
  rb_define_method(cXMLNamespace, "href", rxml_namespace_href_get, 0);
  rb_define_method(cXMLNamespace, "next", rxml_namespace_next, 0);
  rb_define_method(cXMLNamespace, "node_type", rxml_namespace_node_type, 0);
  rb_define_method(cXMLNamespace, "prefix", rxml_namespace_prefix_get, 0);
}
