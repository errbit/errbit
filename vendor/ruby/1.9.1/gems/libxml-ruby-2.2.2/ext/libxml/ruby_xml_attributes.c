/* Please see the LICENSE file for copyright and distribution information */

/*
 * Document-class: LibXML::XML::Attributes
 *
 * Provides access to an element's attributes (XML::Attr).
 *
 * Basic Usage:
 *  require 'test_helper'
 *
 *  doc = XML::Document.new(<some_file>)
 *  attributes = doc.root.attributes
 *
 *  attributes.each do |attribute|
 *    ..
 *  end
 *
 *  attributes['foo'] = 'bar'
 *  attribute = attributes.get_attribute['foo']
 *  attribute.value == 'foo'
 *
 * To access a namespaced attribute:
 *
 *  XLINK_URI = 'http://www.w3.org/1999/xlink'
 *
 *  attribute = attributes.get_attribute_ns(XLINK_URI, 'title')
 *  attribute.value = 'My title'
 */

#include "ruby_libxml.h"
#include "ruby_xml_attributes.h"

VALUE cXMLAttributes;

void rxml_attributes_mark(xmlNodePtr xnode)
{
  rxml_node_mark(xnode);
}

/*
 * Creates a  new attributes instance.  Not exposed to ruby.
 */
VALUE rxml_attributes_new(xmlNodePtr xnode)
{
  return Data_Wrap_Struct(cXMLAttributes, rxml_attributes_mark, NULL, xnode);
}

/*
 * call-seq:
 *   attributes.node -> XML::Node
 *
 * Return the node that owns this attributes list.
 *
 *  doc.root.attributes.node == doc.root
 */
VALUE rxml_attributes_node_get(VALUE self)
{
  xmlNodePtr xnode;
  Data_Get_Struct(self, xmlNode, xnode);
  return rxml_node_wrap(xnode);
}

/*
 * call-seq:
 *    attributes.get_attribute("name") -> (XML::Attr | XML::AtrrDecl)
 *
 * Returns the specified attribute.  If the attribute does not 
 * exist but the document has an associated DTD that defines
 * a default value for the attribute, then a XML::AttrDecl is
 * returned.
 *
 * name: The name of the attribute, not including a namespace.
 *
 *  doc.root.attributes.get_attribute("foo")
 */
static VALUE rxml_attributes_get_attribute(VALUE self, VALUE name)
{
  xmlNodePtr xnode;
  xmlAttrPtr xattr;

  name = rb_obj_as_string(name);

  Data_Get_Struct(self, xmlNode, xnode);

  xattr = xmlHasProp(xnode, (xmlChar*) StringValuePtr(name));

  if (!xattr)
    return Qnil;
  else if (xattr->type == XML_ATTRIBUTE_DECL)
    return rxml_attr_decl_wrap((xmlAttributePtr)xattr);
  else
    return rxml_attr_wrap(xattr);
}

/*
 * call-seq:
 *    attributes.get_attribute_ns("namespace", "name") -> (XML::Attr | XML::AtrrDecl)
 *
 * Returns the specified attribute.  If the attribute does not 
 * exist but the document has an associated DTD that defines
 * a default value for the attribute, then a XML::AttrDecl is
 * returned.
 *
 * namespace: The URI of the attribute's namespace.
 * name: The name of the attribute, not including a namespace.
 *
 *  doc.root.attributes.get_attribute_ns('http://www.w3.org/1999/xlink', 'href')
 */
static VALUE rxml_attributes_get_attribute_ns(VALUE self, VALUE namespace,
    VALUE name)
{
  xmlNodePtr xnode;
  xmlAttrPtr xattr;

  name = rb_obj_as_string(name);

  Data_Get_Struct(self, xmlNode, xnode);

  xattr = xmlHasNsProp(xnode, (xmlChar*) StringValuePtr(name),
                      (xmlChar*) StringValuePtr(namespace));

  if (!xattr)
    return Qnil;
  else if (xattr->type == XML_ATTRIBUTE_DECL)
    return rxml_attr_decl_wrap((xmlAttributePtr)xattr);
  else
    return rxml_attr_wrap(xattr);
}

/*
 * call-seq:
 *    attributes["name"] -> String
 *
 * Fetches an attribute value. If you want to access the underlying
 * Attribute itself use get_attribute.
 *
 * name: The name of the attribute, not including any namespaces.
 *
 *  doc.root.attributes['att'] -> 'some value'
 */
VALUE rxml_attributes_attribute_get(VALUE self, VALUE name)
{
  VALUE xattr = rxml_attributes_get_attribute(self, name);
  
  if (NIL_P(xattr))
    return Qnil;
  else
    return rxml_attr_value_get(xattr);
}

/*
 * call-seq:
 *    attributes["name"] = "value"
 *
 * Sets an attribute value. If you want to get the Attribute itself,
 * use get_attribute.
 *
 * name: The name of the attribute, not including any namespaces.
 * value: The new value of the namespace.
 *
 *  doc.root.attributes['att'] = 'some value'
 */
VALUE rxml_attributes_attribute_set(VALUE self, VALUE name, VALUE value)
{
  VALUE xattr = rxml_attributes_get_attribute(self, name);
  if (NIL_P(xattr))
  {
    VALUE args[3];

    args[0] = rxml_attributes_node_get(self);
    args[1] = name;
    args[2] = value;

    return rb_class_new_instance(sizeof(args)/sizeof(VALUE), args, cXMLAttr);
  }
  else
  {
    return rxml_attr_value_set(xattr, value);
  }
}

/*
 * call-seq:
 *    attributes.each {block} -> XML::Attr
 *
 * Iterates over each attribute.
 *
 *  doc.root.attributes.each {|attribute| puts attribute.name}
 */
static VALUE rxml_attributes_each(VALUE self)
{
  xmlNodePtr xnode;
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlNode, xnode);

  xattr = xnode->properties;

  while (xattr)
  {
    /* Get the next attribute while we still can - the user
       may remove the yielded attribute. */
    xmlAttrPtr next = xattr->next;

    VALUE attr = rxml_attr_wrap(xattr);
    rb_yield(attr);
    xattr = next;
  }

  return self;
}

/*
 * call-seq:
 *    attributes.length -> Integer
 *
 * Returns the number of attributes.
 *
 *  doc.root.attributes.length
 */
static VALUE rxml_attributes_length(VALUE self)
{
  int length = 0;
  xmlNodePtr xnode;
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlNode, xnode);

  xattr = xnode->properties;

  while (xattr)
  {
    length++;
    xattr = xattr->next;
  }
  
  return INT2NUM(length);
}

/*
 * call-seq:
 *    attributes.first -> XML::Attr
 *
 * Returns the first attribute.
 *
 *  doc.root.attributes.first
 */
static VALUE rxml_attributes_first(VALUE self)
{
  xmlNodePtr xnode;
  Data_Get_Struct(self, xmlNode, xnode);

  if (xnode->type == XML_ELEMENT_NODE)
  {
    xmlAttrPtr xattr = xnode->properties;

    if (xattr)
    {
      return rxml_attr_wrap(xattr);
    }
  }
  return Qnil;
}

void rxml_init_attributes(void)
{
  cXMLAttributes = rb_define_class_under(mXML, "Attributes", rb_cObject);
  rb_include_module(cXMLAttributes, rb_mEnumerable);
  rb_define_method(cXMLAttributes, "node", rxml_attributes_node_get, 0);
  rb_define_method(cXMLAttributes, "get_attribute", rxml_attributes_get_attribute, 1);
  rb_define_method(cXMLAttributes, "get_attribute_ns", rxml_attributes_get_attribute_ns, 2);
  rb_define_method(cXMLAttributes, "[]", rxml_attributes_attribute_get, 1);
  rb_define_method(cXMLAttributes, "[]=", rxml_attributes_attribute_set, 2);
  rb_define_method(cXMLAttributes, "each", rxml_attributes_each, 0);
  rb_define_method(cXMLAttributes, "length", rxml_attributes_length, 0);
  rb_define_method(cXMLAttributes, "first", rxml_attributes_first, 0);
}
