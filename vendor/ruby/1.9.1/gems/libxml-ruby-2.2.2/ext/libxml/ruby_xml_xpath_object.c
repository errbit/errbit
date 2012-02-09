#include "ruby_libxml.h"

/*
 * Document-class: LibXML::XML::XPath::Object
 *
 * A collection of nodes returned from the evaluation of an XML::XPath
 * or XML::XPointer expression.
 */

VALUE cXMLXPathObject;


/* Memory management of xpath results is tricky.  If a nodeset is
   returned, it generally consists of pointers to nodes in the 
   original document.  However, namespace nodes are handled differently - 
   libxml creates copies of them instead.  Thus, when an xmlXPathObjectPtr
   is freed, libxml iterates over the results to find the copied namespace 
   nodes to free them.

   This causes problems for the bindings because the underlying document
   may be freed before the xmlXPathObjectPtr instance.  This might seem
   counterintuitive since the xmlXPathObjectPtr marks the document.
   However, once both objects go out of scope, the order of their 
   destruction is random.

   To deal with this, the wrapper code searches for the namespace nodes
   and wraps them in Ruby objects.  When the Ruby objects go out of scope
   then the namespace nodes are freed. */

static void rxml_xpath_object_free(rxml_xpath_object *rxpop)
{
  /* We positively, absolutely cannot let libxml iterate over
     the nodeTab since if the underlying document has been
     freed the majority of entries are invalid, resulting in
     segmentation faults.*/
  if (rxpop->xpop->nodesetval && rxpop->xpop->nodesetval->nodeTab)
  {
    xmlFree(rxpop->xpop->nodesetval->nodeTab);
    rxpop->xpop->nodesetval->nodeTab = NULL;
  }
  xmlXPathFreeObject(rxpop->xpop);
  xfree(rxpop);
}

/* Custom free function for copied namespace nodes */
static void rxml_xpath_namespace_free(xmlNsPtr xns)
{
  xmlFreeNs(xns);
}

static void rxml_xpath_object_mark(rxml_xpath_object *rxpop)
{
  rb_gc_mark(rxpop->nsnodes);
  if (rxpop->xdoc->_private)
    rb_gc_mark((VALUE)rxpop->xdoc->_private);
}

VALUE rxml_xpath_object_wrap(xmlDocPtr xdoc, xmlXPathObjectPtr xpop)
{
  int i;
  rxml_xpath_object *rxpop = ALLOC(rxml_xpath_object);
  rxpop->xdoc =xdoc;
  rxpop->xpop = xpop;
  rxpop->nsnodes = rb_ary_new();

  /* Find all the extra namespace nodes and wrap them. */
  if (xpop->nodesetval && xpop->nodesetval->nodeNr)
  {
    for (i = 0;i < xpop->nodesetval->nodeNr; i++)
    {
      xmlNodePtr xnode = xpop->nodesetval->nodeTab[i];
      if (xnode != NULL && xnode->type == XML_NAMESPACE_DECL)
      {
        VALUE ns = Qnil;
        xmlNsPtr xns = (xmlNsPtr)xnode;

        /* Get rid of libxml's -> next hack.  The issue here is
           the rxml_namespace code assumes that ns->next refers
           to another namespace. */
        xns->next = NULL;

        /* Specify a custom free function here since by default
           namespace nodes will not be freed */
        ns = rxml_namespace_wrap((xmlNsPtr)xnode);
        RDATA(ns)->dfree = (RUBY_DATA_FUNC)rxml_xpath_namespace_free;
        rb_ary_push(rxpop->nsnodes, ns);
      }
    }
  }

  return Data_Wrap_Struct(cXMLXPathObject, rxml_xpath_object_mark, rxml_xpath_object_free, rxpop);
}

static VALUE rxml_xpath_object_tabref(xmlXPathObjectPtr xpop, int index)
{
  if (index < 0)
    index = xpop->nodesetval->nodeNr + index;

  if (index < 0 || index + 1 > xpop->nodesetval->nodeNr)
    return Qnil;

  switch (xpop->nodesetval->nodeTab[index]->type)
  {
  case XML_ATTRIBUTE_NODE:
    return rxml_attr_wrap((xmlAttrPtr) xpop->nodesetval->nodeTab[index]);
    break;
  case XML_NAMESPACE_DECL:
    return rxml_namespace_wrap((xmlNsPtr)xpop->nodesetval->nodeTab[index]);
    break;
  default:
    return rxml_node_wrap(xpop->nodesetval->nodeTab[index]);
  }
}

/*
 * call-seq:
 *    xpath_object.to_a -> [node, ..., node]
 *
 * Obtain an array of the nodes in this set.
 */
static VALUE rxml_xpath_object_to_a(VALUE self)
{
  VALUE set_ary, nodeobj;
  rxml_xpath_object *rxpop;
  xmlXPathObjectPtr xpop;
  int i;

  Data_Get_Struct(self, rxml_xpath_object, rxpop);
  xpop = rxpop->xpop;

  set_ary = rb_ary_new();

  if (!((xpop->nodesetval == NULL) || (xpop->nodesetval->nodeNr == 0)))
  {
    for (i = 0; i < xpop->nodesetval->nodeNr; i++)
    {
      nodeobj = rxml_xpath_object_tabref(xpop, i);
      rb_ary_push(set_ary, nodeobj);
    }
  }

  return (set_ary);
}

/*
 * call-seq:
 *    xpath_object.empty? -> (true|false)
 *
 * Determine whether this nodeset is empty (contains no nodes).
 */
static VALUE rxml_xpath_object_empty_q(VALUE self)
{
  rxml_xpath_object *rxpop;
  Data_Get_Struct(self, rxml_xpath_object, rxpop);

  if (rxpop->xpop->type != XPATH_NODESET)
    return Qnil;

  return (rxpop->xpop->nodesetval == NULL || rxpop->xpop->nodesetval->nodeNr <= 0) ? Qtrue
      : Qfalse;
}

/*
 * call-seq:
 *    xpath_object.each { |node| ... } -> self
 *
 * Call the supplied block for each node in this set.
 */
static VALUE rxml_xpath_object_each(VALUE self)
{
  rxml_xpath_object *rxpop;
  int i;

  if (rxml_xpath_object_empty_q(self) == Qtrue)
    return Qnil;

  Data_Get_Struct(self, rxml_xpath_object, rxpop);

  for (i = 0; i < rxpop->xpop->nodesetval->nodeNr; i++)
  {
    rb_yield(rxml_xpath_object_tabref(rxpop->xpop, i));
  }
  return (self);
}

/*
 * call-seq:
 *    xpath_object.first -> node
 *
 * Returns the first node in this node set, or nil if none exist.
 */
static VALUE rxml_xpath_object_first(VALUE self)
{
  rxml_xpath_object *rxpop;

  if (rxml_xpath_object_empty_q(self) == Qtrue)
    return Qnil;

  Data_Get_Struct(self, rxml_xpath_object, rxpop);
  return rxml_xpath_object_tabref(rxpop->xpop, 0);
}

/*
 * call-seq:
 *    xpath_object.last -> node
 *
 * Returns the last node in this node set, or nil if none exist.
 */
static VALUE rxml_xpath_object_last(VALUE self)
{
  rxml_xpath_object *rxpop;

  if (rxml_xpath_object_empty_q(self) == Qtrue)
    return Qnil;

  Data_Get_Struct(self, rxml_xpath_object, rxpop);
  return rxml_xpath_object_tabref(rxpop->xpop, -1);
}

/*
 * call-seq:
 * xpath_object[i] -> node
 *
 * array index into set of nodes
 */
static VALUE rxml_xpath_object_aref(VALUE self, VALUE aref)
{
  rxml_xpath_object *rxpop;

  if (rxml_xpath_object_empty_q(self) == Qtrue)
    return Qnil;

  Data_Get_Struct(self, rxml_xpath_object, rxpop);
  return rxml_xpath_object_tabref(rxpop->xpop, NUM2INT(aref));
}

/*
 * call-seq:
 *    xpath_object.length -> num
 *
 * Obtain the length of the nodesetval node list.
 */
static VALUE rxml_xpath_object_length(VALUE self)
{
  rxml_xpath_object *rxpop;

  if (rxml_xpath_object_empty_q(self) == Qtrue)
    return INT2FIX(0);

  Data_Get_Struct(self, rxml_xpath_object, rxpop);
  return INT2NUM(rxpop->xpop->nodesetval->nodeNr);
}

/*
 * call-seq:
 *    xpath_object.xpath_type -> int
 *
 * Returns the XPath type of the result object.
 * Possible values are defined as constants
 * on the XML::XPath class and include:
 *
 * * XML::XPath::UNDEFINED
 * * XML::XPath::NODESET
 * * XML::XPath::BOOLEAN
 * * XML::XPath::NUMBER
 * * XML::XPath::STRING
 * * XML::XPath::POINT
 * * XML::XPath::RANGE
 * * XML::XPath::LOCATIONSET
 * * XML::XPath::USERS
 * * XML::XPath::XSLT_TREE
 */
static VALUE rxml_xpath_object_get_type(VALUE self)
{
  rxml_xpath_object *rxpop;
  Data_Get_Struct(self, rxml_xpath_object, rxpop);
  return INT2FIX(rxpop->xpop->type);
}

/*
 * call-seq:
 *    xpath_object.string -> String
 *
 * Returns the original XPath expression as a string.
 */
static VALUE rxml_xpath_object_string(VALUE self)
{
  rxml_xpath_object *rxpop;

  Data_Get_Struct(self, rxml_xpath_object, rxpop);

  if (rxpop->xpop->stringval == NULL)
    return Qnil;

  return rxml_new_cstr((const char*) rxpop->xpop->stringval, rxpop->xdoc->encoding);
}

/*
 * call-seq:
 *    nodes.debug -> (true|false)
 *
 * Dump libxml debugging information to stdout.
 * Requires Libxml be compiled with debugging enabled.
 */
static VALUE rxml_xpath_object_debug(VALUE self)
{
#ifdef LIBXML_DEBUG_ENABLED
  rxml_xpath_object *rxpop;
  Data_Get_Struct(self, rxml_xpath_object, rxpop);
  xmlXPathDebugDumpObject(stdout, rxpop->xpop, 0);
  return Qtrue;
#else
  rb_warn("libxml was compiled without debugging support.")
  return Qfalse;
#endif
}

void rxml_init_xpath_object(void)
{
  cXMLXPathObject = rb_define_class_under(mXPath, "Object", rb_cObject);
  rb_include_module(cXMLXPathObject, rb_mEnumerable);
  rb_define_attr(cXMLXPathObject, "context", 1, 0);
  rb_define_method(cXMLXPathObject, "each", rxml_xpath_object_each, 0);
  rb_define_method(cXMLXPathObject, "xpath_type", rxml_xpath_object_get_type, 0);
  rb_define_method(cXMLXPathObject, "empty?", rxml_xpath_object_empty_q, 0);
  rb_define_method(cXMLXPathObject, "first", rxml_xpath_object_first, 0);
  rb_define_method(cXMLXPathObject, "last", rxml_xpath_object_last, 0);
  rb_define_method(cXMLXPathObject, "length", rxml_xpath_object_length, 0);
  rb_define_method(cXMLXPathObject, "to_a", rxml_xpath_object_to_a, 0);
  rb_define_method(cXMLXPathObject, "[]", rxml_xpath_object_aref, 1);
  rb_define_method(cXMLXPathObject, "string", rxml_xpath_object_string, 0);
  rb_define_method(cXMLXPathObject, "debug", rxml_xpath_object_debug, 0);
}
