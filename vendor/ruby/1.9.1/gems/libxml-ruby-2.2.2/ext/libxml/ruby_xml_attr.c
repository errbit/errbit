/* Please see the LICENSE file for copyright and distribution information */

/*
 * Document-class: LibXML::XML::Attr
 *
 * Provides access to an attribute defined on an element.
 *
 * Basic Usage:
 *
 *  require 'test_helper'
 *
 *  doc = XML::Document.new(<some_file>)
 *  attribute = doc.root.attributes.get_attribute_ns('http://www.w3.org/1999/xlink', 'href')
 *  attribute.name == 'href'
 *  attribute.value == 'http://www.mydocument.com'
 *  attribute.remove!
 */

/* Attributes are owned and freed by their nodes.  Thus, its easier for the
   ruby bindings to not manage attribute memory management.  This does mean
   that accessing a particular attribute multiple times will return multiple
   different ruby objects.  Since we are not using free or xnode->_private
   this works out fine.  Previous versions of the bindings had a one to
   one mapping between ruby object and xml attribute, but that could 
   result in segfaults because the ruby object could be gc'ed.  In theory
   the mark method on the parent node could prevent that, but if an 
   attribute is returned using an xpath statement then the node would
   never by surfaced to ruby and the mark method never called. */

#include "ruby_libxml.h"
#include "ruby_xml_attr.h"

VALUE cXMLAttr;

void rxml_attr_mark(xmlAttrPtr xattr)
{
  /* This can happen if Ruby does a GC run after creating the
     new attribute but before initializing it. */
  if (xattr != NULL)
    rxml_node_mark((xmlNodePtr) xattr);
}

VALUE rxml_attr_wrap(xmlAttrPtr xattr)
{
  return Data_Wrap_Struct(cXMLAttr, rxml_attr_mark, NULL, xattr);
}

static VALUE rxml_attr_alloc(VALUE klass)
{
  return Data_Wrap_Struct(klass, rxml_attr_mark, NULL, NULL);
}

/*
 * call-seq:
 *    attr.initialize(node, "name", "value")
 *
 * Creates a new attribute for the node.
 *
 * node: The XML::Node that will contain the attribute
 * name: The name of the attribute
 * value: The value of the attribute
 *
 *  attr = XML::Attr.new(doc.root, 'name', 'libxml')
 */
static VALUE rxml_attr_initialize(int argc, VALUE *argv, VALUE self)
{
  VALUE node = argv[0];
  VALUE name = argv[1];
  VALUE value = argv[2];
  VALUE ns = (argc == 4 ? argv[3] : Qnil);

  xmlNodePtr xnode;
  xmlAttrPtr xattr;

  if (argc < 3 || argc > 4)
    rb_raise(rb_eArgError, "Wrong number of arguments (3 or 4)");

  Check_Type(name, T_STRING);
  Check_Type(value, T_STRING);

  Data_Get_Struct(node, xmlNode, xnode);

  if (xnode->type != XML_ELEMENT_NODE)
    rb_raise(rb_eArgError, "Attributes can only be created on element nodes.");

  if (NIL_P(ns))
  {
    xattr = xmlNewProp(xnode, (xmlChar*)StringValuePtr(name), (xmlChar*)StringValuePtr(value));
  }
  else
  {
    xmlNsPtr xns;
    Data_Get_Struct(ns, xmlNs, xns);
    xattr = xmlNewNsProp(xnode, xns, (xmlChar*)StringValuePtr(name), (xmlChar*)StringValuePtr(value));
  }

  if (!xattr)
    rb_raise(rb_eRuntimeError, "Could not create attribute.");

  DATA_PTR( self) = xattr;
  return self;
}

/*
 * call-seq:
 *    attr.child -> node
 *
 * Obtain this attribute's child attribute(s).
 */
static VALUE rxml_attr_child_get(VALUE self)
{
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlAttr, xattr);
  if (xattr->children == NULL)
    return Qnil;
  else
    return rxml_node_wrap((xmlNodePtr) xattr->children);
}


/*
 * call-seq:
 *    attr.doc -> XML::Document
 *
 * Returns this attribute's document.
 *
 *  doc.root.attributes.get_attribute('name').doc == doc
 */
static VALUE rxml_attr_doc_get(VALUE self)
{
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlAttr, xattr);
  if (xattr->doc == NULL)
    return Qnil;
  else
    return rxml_document_wrap(xattr->doc);
}

/*
 * call-seq:
 *    attr.last -> node
 *
 * Obtain the last attribute.
 */
static VALUE rxml_attr_last_get(VALUE self)
{
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlAttr, xattr);
  if (xattr->last == NULL)
    return Qnil;
  else
    return rxml_node_wrap(xattr->last);
}

/*
 * call-seq:
 *    attr.name -> "name"
 *
 * Obtain this attribute's name.
 */
static VALUE rxml_attr_name_get(VALUE self)
{
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlAttr, xattr);

  if (xattr->name == NULL)
    return Qnil;
  else
    return rxml_new_cstr((const char*) xattr->name, NULL);
}

/*
 * call-seq:
 *    attr.next -> node
 *
 * Obtain the next attribute.
 */
static VALUE rxml_attr_next_get(VALUE self)
{
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlAttr, xattr);
  if (xattr->next == NULL)
    return Qnil;
  else
    return rxml_attr_wrap(xattr->next);
}

/*
 * call-seq:
 *    attr.node_type -> num
 *
 * Obtain this node's type identifier.
 */
static VALUE rxml_attr_node_type(VALUE self)
{
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlAttr, xattr);
  return INT2NUM(xattr->type);
}

/*
 * call-seq:
 *    attr.ns -> namespace
 *
 * Obtain this attribute's associated XML::NS, if any.
 */
static VALUE rxml_attr_ns_get(VALUE self)
{
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlAttr, xattr);
  if (xattr->ns == NULL)
    return Qnil;
  else
    return rxml_namespace_wrap(xattr->ns);
}

/*
 * call-seq:
 *    attr.parent -> node
 *
 * Obtain this attribute node's parent.
 */
static VALUE rxml_attr_parent_get(VALUE self)
{
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlAttr, xattr);
  if (xattr->parent == NULL)
    return Qnil;
  else
    return rxml_node_wrap(xattr->parent);
}

/*
 * call-seq:
 *    attr.prev -> node
 *
 * Obtain the previous attribute.
 */
static VALUE rxml_attr_prev_get(VALUE self)
{
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlAttr, xattr);
  if (xattr->prev == NULL)
    return Qnil;
  else
    return rxml_attr_wrap(xattr->prev);
}

/*
 * call-seq:
 *     attr.remove! -> nil
 *
 * Removes this attribute from it's parent.  Note
 * the attribute and its content is freed and can
 * no longer be used.  If you try to use it you 
 * will get a segmentation fault.
 */
static VALUE rxml_attr_remove_ex(VALUE self)
{
  xmlAttrPtr xattr;
  Data_Get_Struct(self, xmlAttr, xattr);
  xmlRemoveProp(xattr);

  RDATA(self)->data = NULL;
  RDATA(self)->dfree = NULL;
  RDATA(self)->dmark = NULL;

  return Qnil;
}

/*
 * call-seq:
 *    attr.value -> "value"
 *
 * Obtain the value of this attribute.
 */
VALUE rxml_attr_value_get(VALUE self)
{
  xmlAttrPtr xattr;
  xmlChar *value;
  VALUE result = Qnil;

  Data_Get_Struct(self, xmlAttr, xattr);
  value = xmlNodeGetContent((xmlNodePtr)xattr);

  if (value != NULL)
  {
    result = rxml_new_cstr((const char*) value, NULL);
    xmlFree(value);
  }
  return result;
}

/*
 * call-seq:
 *    attr.value = "value"
 *
 * Sets the value of this attribute.
 */
VALUE rxml_attr_value_set(VALUE self, VALUE val)
{
  xmlAttrPtr xattr;

  Check_Type(val, T_STRING);
  Data_Get_Struct(self, xmlAttr, xattr);

  if (xattr->ns)
    xmlSetNsProp(xattr->parent, xattr->ns, xattr->name,
        (xmlChar*) StringValuePtr(val));
  else
    xmlSetProp(xattr->parent, xattr->name, (xmlChar*) StringValuePtr(val));

  return (self);
}

void rxml_init_attr(void)
{
  cXMLAttr = rb_define_class_under(mXML, "Attr", rb_cObject);
  rb_define_alloc_func(cXMLAttr, rxml_attr_alloc);
  rb_define_method(cXMLAttr, "initialize", rxml_attr_initialize, -1);
  rb_define_method(cXMLAttr, "child", rxml_attr_child_get, 0);
  rb_define_method(cXMLAttr, "doc", rxml_attr_doc_get, 0);
  rb_define_method(cXMLAttr, "last", rxml_attr_last_get, 0);
  rb_define_method(cXMLAttr, "name", rxml_attr_name_get, 0);
  rb_define_method(cXMLAttr, "next", rxml_attr_next_get, 0);
  rb_define_method(cXMLAttr, "node_type", rxml_attr_node_type, 0);
  rb_define_method(cXMLAttr, "ns", rxml_attr_ns_get, 0);
  rb_define_method(cXMLAttr, "parent", rxml_attr_parent_get, 0);
  rb_define_method(cXMLAttr, "prev", rxml_attr_prev_get, 0);
  rb_define_method(cXMLAttr, "remove!", rxml_attr_remove_ex, 0);
  rb_define_method(cXMLAttr, "value", rxml_attr_value_get, 0);
  rb_define_method(cXMLAttr, "value=", rxml_attr_value_set, 1);
}
