/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"
#include "ruby_xml_namespaces.h"

VALUE cXMLNamespaces;

/* Document-class: LibXML::XML::Namespaces
 *
 * The XML::Namespaces class is used to access information about
 * a node's namespaces.  For each node, libxml maintains:
 *
 * * The node's namespace (#namespace)
 * * Which namespaces are defined on the node (#definnitions)
 * * Which namespaces are in scope for the node (#each)
 *
 * Let's look at an example:
 *
 *   <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
 *                  xmlns:xsd="http://www.w3.org/2001/XMLSchema">
 *     <soap:Body>
 *       <order xmlns="http://mynamespace.com"/>
 *     </soap:Body>
 *   </soap>
 *
 * The Envelope node is in the soap namespace.  It contains
 * two namespace definitions, one for soap and one for xsd.
 * 
 * The Body node is also in the soap namespace and does not
 * contain any namespaces.  However, the soap and xsd namespaces
 * are both in context.
 *
 * The order node is in its default namespace and contains
 * one namespace definition (http://mynamespace.com).  There
 * are three namespaces in context soap, xsd and the 
 * default namespace.
*/

static VALUE rxml_namespaces_alloc(VALUE klass)
{
  return Data_Wrap_Struct(klass, NULL, NULL, NULL);
}

/*
 * call-seq:
 *    initialize(XML::Node) -> XML::Namespaces
 *
 * Creates a new namespaces object.  Generally you
 * do not call this method directly, but instead
 * access a namespaces object via XML::Node#namespaces.
 *
 * Usage:
 *
 *   doc = XML::Document.string('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"/>')
 *   namespaces = new XML::Namespaces(doc.root)
 */
static VALUE rxml_namespaces_initialize(VALUE self, VALUE node)
{
  xmlNodePtr xnode;

  Check_Type(node, T_DATA);
  Data_Get_Struct(node, xmlNode, xnode);

  DATA_PTR(self) = xnode;
  return self;
}

/*
 * call-seq:
 *    namespaces.definitions -> [XML::Namespace, XML::Namespace]
 *
 * Returns an array of XML::Namespace objects that are 
 * defined on this node.
 *
 * Usage:
 *
 *   doc = XML::Document.string('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"/>')
 *   defs = doc.root.namespaces.definitions
 */
static VALUE rxml_namespaces_definitions(VALUE self)
{
  xmlNodePtr xnode;
  xmlNsPtr xns;
  VALUE arr;

  Data_Get_Struct(self, xmlNode, xnode);

  arr = rb_ary_new();
  xns = xnode->nsDef;

  while (xns)
  {
    VALUE anamespace = rxml_namespace_wrap(xns);
    rb_ary_push(arr, anamespace);
    xns = xns->next;
  }

  return arr;
}

/*
 * call-seq:
 *    namespaces.each {|XML::Namespace|}
 *
 * Iterates over the namespace objects that are
 * in context for this node.
 *
 * Usage:
 *
 *   doc = XML::Document.string('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"/>')
 *   doc.root.namespaces.each do |ns|
 *     ..
 *   end
 */
static VALUE rxml_namespaces_each(VALUE self)
{
  xmlNodePtr xnode;
  xmlNsPtr *nsList, *xns;

  Data_Get_Struct(self, xmlNode, xnode);

  nsList = xmlGetNsList(xnode->doc, xnode);

  if (nsList == NULL)
    return (Qnil);

  for (xns = nsList; *xns != NULL; xns++)
  {
    VALUE ns = rxml_namespace_wrap(*xns);
    rb_yield(ns);
  }
  xmlFree(nsList);

  return Qnil;
}

/*
 * call-seq:
 *    namespaces.find_by_href(href) -> XML::Namespace
 *
 * Searches for a namespace that has the specified href.
 * The search starts at the current node and works upward
 * through the node's parents.  If a namespace is found,
 * then an XML::Namespace instance is returned, otherwise nil
 * is returned.
 *
 * Usage:
 *
 *   doc = XML::Document.string('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"/>')
 *   ns = doc.root.namespaces.find_by_href('http://schemas.xmlsoap.org/soap/envelope/')
 *   assert_equal('soap', ns.prefix)
 *   assert_equal('http://schemas.xmlsoap.org/soap/envelope/', ns.href)
 */
static VALUE rxml_namespaces_find_by_href(VALUE self, VALUE href)
{
  xmlNodePtr xnode;
  xmlNsPtr xns;

  Check_Type(href, T_STRING);
  Data_Get_Struct(self, xmlNode, xnode);

  xns = xmlSearchNsByHref(xnode->doc, xnode, (xmlChar*) StringValuePtr(href));
  if (xns)
    return rxml_namespace_wrap(xns);
  else
    return Qnil;
}

/*
 * call-seq:
 *    namespaces.find_by_prefix(prefix=nil) -> XML::Namespace
 *
 * Searches for a namespace that has the specified prefix.
 * The search starts at the current node and works upward
 * through the node's parents.  If a namespace is found,
 * then an XML::Namespace instance is returned, otherwise nil
 * is returned.
 *
 * Usage:
 *
 *   doc = XML::Document.string('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"/>')
 *   ns = doc.root.namespaces.find_by_prefix('soap')
 *   assert_equal('soap', ns.prefix)
 *   assert_equal('http://schemas.xmlsoap.org/soap/envelope/', ns.href)
 */
static VALUE rxml_namespaces_find_by_prefix(VALUE self, VALUE prefix)
{
  xmlNodePtr xnode;
  xmlNsPtr xns;
  xmlChar* xprefix = NULL;

  
  if (!NIL_P(prefix))
  {
    Check_Type(prefix, T_STRING);
    xprefix = (xmlChar*) StringValuePtr(prefix);
  }

  Data_Get_Struct(self, xmlNode, xnode);
  
  xns = xmlSearchNs(xnode->doc, xnode, xprefix);
  if (xns)
    return rxml_namespace_wrap(xns);
  else
    return Qnil;
}

/*
 * call-seq:
 *    namespaces.namespace -> XML::Namespace
 *
 * Returns the current node's namespace.
 *
 * Usage:
 *
 *   doc = XML::Document.string('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"/>')
 *   ns = doc.root.namespaces.namespace
 *   assert_equal('soap', ns.prefix)
 *   assert_equal('http://schemas.xmlsoap.org/soap/envelope/', ns.href)
 */
static VALUE rxml_namespaces_namespace_get(VALUE self)
{
  xmlNodePtr xnode;
  Data_Get_Struct(self, xmlNode, xnode);

  if (xnode->ns)
    return rxml_namespace_wrap(xnode->ns);
  else
    return Qnil;
}

/*
 * call-seq:
 *    namespaces.namespace = XML::Namespace
 *
 * Sets the current node's namespace.  
 *
 * Basic usage:
 *
 *   # Create a node
 *   node = XML::Node.new('Envelope')
 *   
 *   # Define the soap namespace - this does *not* put the node in the namespace
 *   ns = XML::Namespace.new(node, 'soap', 'http://schemas.xmlsoap.org/soap/envelope/')
 *   assert_equal("<Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"/>", node.to_s)
 *
 *   # Now put the node in the soap namespace, not how the string representation changes
 *   node.namespaces.namespace = ns
 *   assert_equal("<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"/>", node.to_s)
 */
static VALUE rxml_namespaces_namespace_set(VALUE self, VALUE ns)
{
  xmlNodePtr xnode;
  xmlNsPtr xns;

  Data_Get_Struct(self, xmlNode, xnode);

  Check_Type(ns, T_DATA);
  Data_Get_Struct(ns, xmlNs, xns);

  xmlSetNs(xnode, xns);
  return self;
}

/*
 * call-seq:
 *    namespaces.node -> XML::Node
 *
 * Returns the current node.
 */
static VALUE rxml_namespaces_node_get(VALUE self)
{
  xmlNodePtr xnode;
  Data_Get_Struct(self, xmlNode, xnode);
  return rxml_node_wrap(xnode);
}

void rxml_init_namespaces(void)
{
  cXMLNamespaces = rb_define_class_under(mXML, "Namespaces", rb_cObject);
  rb_include_module(cXMLNamespaces, rb_mEnumerable);

  rb_define_alloc_func(cXMLNamespaces, rxml_namespaces_alloc);
  rb_define_method(cXMLNamespaces, "initialize", rxml_namespaces_initialize, 1);

  rb_define_method(cXMLNamespaces, "definitions", rxml_namespaces_definitions, 0);
  rb_define_method(cXMLNamespaces, "each", rxml_namespaces_each, 0);
  rb_define_method(cXMLNamespaces, "find_by_href", rxml_namespaces_find_by_href, 1);
  rb_define_method(cXMLNamespaces, "find_by_prefix", rxml_namespaces_find_by_prefix, 1);
  rb_define_method(cXMLNamespaces, "namespace", rxml_namespaces_namespace_get, 0);
  rb_define_method(cXMLNamespaces, "namespace=", rxml_namespaces_namespace_set, 1);
  rb_define_method(cXMLNamespaces, "node", rxml_namespaces_node_get, 0);
}
