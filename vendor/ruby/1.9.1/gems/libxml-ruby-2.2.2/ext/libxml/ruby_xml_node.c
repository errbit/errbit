#include "ruby_libxml.h"
#include "ruby_xml_node.h"
#include <assert.h>

VALUE cXMLNode;

/* Document-class: LibXML::XML::Node
 *
 * Nodes are the primary objects that make up an XML document.
 * The node class represents most node types that are found in
 * an XML document (but not LibXML::XML::Attributes, see LibXML::XML::Attr).
 * It exposes libxml's full API for creating, querying
 * moving and deleting node objects.  Many of these methods are
 * documented in the DOM Level 3 specification found at:
 * http://www.w3.org/TR/DOM-Level-3-Core/. */


/* Memory management:
 *
 * The bindings create a one-to-one mapping between libxml nodes
 * and Ruby nodes.  If a libxml node is wraped, its _private member
 * is set with a reference to the Ruby object.
 *
 * When a libxml document or top level node is freed, it will free
 * all its children.  Thus Ruby is responsible for:
 *
 *  * Using the mark function to keep alive any documents Ruby is
 *    referencing via the document or child nodes.
 *  * Using the mark function to keep alive any top level, free
 *    standing nodes Ruby is referencing via the node or its children.
 *
 * In general use, this will cause Ruby nodes to be freed before
 * a libxml document.  When a Ruby node is freed, the _private
 * field is set back to null.  
 *
 * In the sweep phase in Ruby 1.9.*, the document tends to be
 * freed before the nodes.  To support this, the bindings register
 * a callback function with libxml that is called each time a node
 * is freed.  In that case, the data_ptr is set to null, so the bindings
 * can recognize the situation.
 */

static void rxml_node_deregisterNode(xmlNodePtr xnode)
{
  /* Has the node been wrapped and exposed to Ruby? */
  if (xnode->_private)
  {
    /* Node was wrapped.  Set the _private member to free and
      then dislabe the dfree function so that Ruby will not
      try to free the node a second time. */
    VALUE node = (VALUE) xnode->_private;
    RDATA(node)->data = NULL;
    RDATA(node)->dfree = NULL;
    RDATA(node)->dmark = NULL;
  }
}

static void rxml_node_free(xmlNodePtr xnode)
{
  /* Either the node has been created yet in initialize
     or it has been freed by libxml already in Ruby's 
     mark phase. */
  if (xnode == NULL)
    return;

  /* The ruby object wrapping the xml object no longer exists. */
  xnode->_private = NULL;

  /* Ruby is responsible for freeing this node if it does not
     have a parent and is not owned by a document.  Note a corner
     case here - calling node2 = doc.import(node1) will cause node2
     to not have a parent but to have a document. */
  if (xnode->parent == NULL)
  {
    xmlFreeNode(xnode);
  }
}

 void rxml_node_mark(xmlNodePtr xnode)
{
  /* Either the node has not been created yet in initialize
     or it has been freed by libxml already in Ruby's 
     mark phase. */
  if (xnode == NULL)
    return;

  if (xnode->doc && xnode->doc->_private)
    rb_gc_mark((VALUE) xnode->doc->_private);
  
  if (xnode->parent && xnode->parent->_private)
    rb_gc_mark((VALUE) xnode->_private);
}

VALUE rxml_node_wrap(xmlNodePtr xnode)
{
  VALUE result;

  /* Is the node already wrapped? */
  if (xnode->_private != NULL)
  {
    result = (VALUE) xnode->_private;
  }
  else
  {
    result = Data_Wrap_Struct(cXMLNode, rxml_node_mark, rxml_node_free, xnode);
    xnode->_private = (void*) result;
  }
  return result;
}

static VALUE rxml_node_alloc(VALUE klass)
{
  /* Ruby is responsible for freeing this node not libxml but don't set
     up mark and free yet until we assign the node. */
  return Data_Wrap_Struct(klass, rxml_node_mark, rxml_node_free, NULL);
}

static xmlNodePtr rxml_get_xnode(VALUE node)
{
   xmlNodePtr result;
   Data_Get_Struct(node, xmlNode, result);

   if (!result)
    rb_raise(rb_eRuntimeError, "This node has already been freed.");

   return result;
}

/*
 * call-seq:
 *    XML::Node.new_cdata(content = nil) -> XML::Node
 *
 * Create a new #CDATA node, optionally setting
 * the node's content.
 */
static VALUE rxml_node_new_cdata(int argc, VALUE *argv, VALUE klass)
{
  VALUE content = Qnil;
  xmlNodePtr xnode;

  rb_scan_args(argc, argv, "01", &content);

  if (NIL_P(content))
  {
    xnode = xmlNewCDataBlock(NULL, NULL, 0);
  }
  else
  {
    content = rb_obj_as_string(content);
    xnode = xmlNewCDataBlock(NULL, (xmlChar*) StringValuePtr(content),
        RSTRING_LEN(content));
  }

  if (xnode == NULL)
    rxml_raise(&xmlLastError);

  return rxml_node_wrap(xnode);
}

/*
 * call-seq:
 *    XML::Node.new_comment(content = nil) -> XML::Node
 *
 * Create a new comment node, optionally setting
 * the node's content.
 *
 */
static VALUE rxml_node_new_comment(int argc, VALUE *argv, VALUE klass)
{
  VALUE content = Qnil;
  xmlNodePtr xnode;

  rb_scan_args(argc, argv, "01", &content);

  if (NIL_P(content))
  {
    xnode = xmlNewComment(NULL);
  }
  else
  {
    content = rb_obj_as_string(content);
    xnode = xmlNewComment((xmlChar*) StringValueCStr(content));
  }

  if (xnode == NULL)
    rxml_raise(&xmlLastError);

  return rxml_node_wrap(xnode);
}

/*
 * call-seq:
 *    XML::Node.new_text(content) -> XML::Node
 *
 * Create a new text node.
 *
 */
static VALUE rxml_node_new_text(VALUE klass, VALUE content)
{
  xmlNodePtr xnode;
  Check_Type(content, T_STRING);
  content = rb_obj_as_string(content);

  xnode = xmlNewText((xmlChar*) StringValueCStr(content));

  if (xnode == NULL)
    rxml_raise(&xmlLastError);

  return rxml_node_wrap(xnode);
}

static VALUE rxml_node_content_set(VALUE self, VALUE content);

/*
 * call-seq:
 *    XML::Node.initialize(name, content = nil, namespace = nil) -> XML::Node
 *
 * Creates a new element with the specified name, content and
 * namespace. The content and namespace may be nil.
 */
static VALUE rxml_node_initialize(int argc, VALUE *argv, VALUE self)
{
  VALUE name;
  VALUE content;
  VALUE ns;
  xmlNodePtr xnode = NULL;
  xmlNsPtr xns = NULL;

  rb_scan_args(argc, argv, "12", &name, &content, &ns);

  name = rb_obj_as_string(name);

  if (!NIL_P(ns))
    Data_Get_Struct(ns, xmlNs, xns);

  xnode = xmlNewNode(xns, (xmlChar*) StringValuePtr(name));

  if (xnode == NULL)
    rxml_raise(&xmlLastError);

  /* Link the Ruby object to the libxml object and vice-versa. */
  xnode->_private = (void*) self;
  DATA_PTR(self) = xnode;

  if (!NIL_P(content))
    rxml_node_content_set(self, content);

  return self;
}

static VALUE rxml_node_modify_dom(VALUE self, VALUE target,
                                  xmlNodePtr (*xmlFunc)(xmlNodePtr, xmlNodePtr))
{
  xmlNodePtr xnode, xtarget, xresult;

  if (rb_obj_is_kind_of(target, cXMLNode) == Qfalse)
    rb_raise(rb_eTypeError, "Must pass an XML::Node object");

  xnode = rxml_get_xnode(self);
  xtarget = rxml_get_xnode(target);

  if (xtarget->doc != NULL && xtarget->doc != xnode->doc)
    rb_raise(eXMLError, "Nodes belong to different documents.  You must first import the node by calling XML::Document.import");

  xmlUnlinkNode(xtarget);

  /* This target node could be freed here. */  
  xresult = xmlFunc(xnode, xtarget);

  if (!xresult)
    rxml_raise(&xmlLastError);

  /* Was the target freed? If yes, then wrap the new node */
  if (xresult != xtarget)
  {
    RDATA(target)->data = xresult;
    xresult->_private = (void*) target;
  }

  return target;
}

/*
 * call-seq:
 *    node.base_uri -> "uri"
 *
 * Obtain this node's base URI.
 */
static VALUE rxml_node_base_uri_get(VALUE self)
{
  xmlNodePtr xnode;
  xmlChar* base_uri;
  VALUE result = Qnil;

  xnode = rxml_get_xnode(self);

  if (xnode->doc == NULL)
    return (result);

  base_uri = xmlNodeGetBase(xnode->doc, xnode);
  if (base_uri)
  {
    result = rxml_new_cstr((const char*) base_uri, NULL);
    xmlFree(base_uri);
  }

  return (result);
}

// TODO node_base_set should support setting back to nil

/*
 * call-seq:
 *    node.base_uri = "uri"
 *
 * Set this node's base URI.
 */
static VALUE rxml_node_base_uri_set(VALUE self, VALUE uri)
{
  xmlNodePtr xnode;

  Check_Type(uri, T_STRING);
  xnode = rxml_get_xnode(self);
  if (xnode->doc == NULL)
    return (Qnil);

  xmlNodeSetBase(xnode, (xmlChar*) StringValuePtr(uri));
  return (Qtrue);
}

/*
 * call-seq:
 *    node.content -> "string"
 *
 * Obtain this node's content as a string.
 */
static VALUE rxml_node_content_get(VALUE self)
{
  xmlNodePtr xnode;
  xmlChar *content;
  VALUE result = Qnil;

  xnode = rxml_get_xnode(self);
  content = xmlNodeGetContent(xnode);
  if (content)
  {
    result = rxml_new_cstr((const char *) content, NULL);
    xmlFree(content);
  }

  return result;
}

/*
 * call-seq:
 *    node.content = "string"
 *
 * Set this node's content to the specified string.
 */
static VALUE rxml_node_content_set(VALUE self, VALUE content)
{
  xmlNodePtr xnode;

  Check_Type(content, T_STRING);
  xnode = rxml_get_xnode(self);
  // XXX docs indicate need for escaping entites, need to be done? danj
  xmlNodeSetContent(xnode, (xmlChar*) StringValuePtr(content));
  return (Qtrue);
}

/*
 * call-seq:
 *    node.content_stripped -> "string"
 *
 * Obtain this node's stripped content.
 *
 * *Deprecated*: Stripped content can be obtained via the
 * +content+ method.
 */
static VALUE rxml_node_content_stripped_get(VALUE self)
{
  xmlNodePtr xnode;
  xmlChar* content;
  VALUE result = Qnil;

  xnode = rxml_get_xnode(self);

  if (!xnode->content)
    return result;

  content = xmlNodeGetContent(xnode);
  if (content)
  {
    result = rxml_new_cstr((const char*) content, NULL);
    xmlFree(content);
  }
  return (result);
}

/*
 * call-seq:
 *    node.debug -> true|false
 *
 * Print libxml debugging information to stdout.
 * Requires that libxml was compiled with debugging enabled.
*/
static VALUE rxml_node_debug(VALUE self)
{
#ifdef LIBXML_DEBUG_ENABLED
  xmlNodePtr xnode;
  xnode = rxml_get_xnode(self);
  xmlDebugDumpNode(NULL, xnode, 2);
  return Qtrue;
#else
  rb_warn("libxml was compiled without debugging support.")
  return Qfalse;
#endif
}

/*
 * call-seq:
 *    node.first -> XML::Node
 *
 * Returns this node's first child node if any.
 */
static VALUE rxml_node_first_get(VALUE self)
{
  xmlNodePtr xnode;

  xnode = rxml_get_xnode(self);

  if (xnode->children)
    return (rxml_node_wrap(xnode->children));
  else
    return (Qnil);
}


/*
 * call-seq:
 *   curr_node << "Some text" 
 *   curr_node << node
 *
 * Add  the specified text or XML::Node as a new child node to the 
 * current node.
 *
 * If the specified argument is a string, it should be a raw string 
 * that contains unescaped XML special characters.  Entity references 
 * are not supported.
 * 
 * The method will return the current node.
 */
static VALUE rxml_node_content_add(VALUE self, VALUE obj)
{
  xmlNodePtr xnode;
  VALUE str;

  xnode = rxml_get_xnode(self);

  /* XXX This should only be legal for a CDATA type node, I think,
   * resulting in a merge of content, as if a string were passed
   * danj 070827
   */
  if (rb_obj_is_kind_of(obj, cXMLNode))
  { 
    rxml_node_modify_dom(self, obj, xmlAddChild);
  }
  else
  {
    str = rb_obj_as_string(obj);
    if (NIL_P(str) || TYPE(str) != T_STRING)
      rb_raise(rb_eTypeError, "invalid argument: must be string or XML::Node");

    xmlNodeAddContent(xnode, (xmlChar*) StringValuePtr(str));
  }
  return self;
}

/*
 * call-seq:
 *    node.doc -> document
 *
 * Obtain the XML::Document this node belongs to.
 */
static VALUE rxml_node_doc(VALUE self)
{
  xmlDocPtr xdoc = NULL;
  xmlNodePtr xnode = rxml_get_xnode(self);

  switch (xnode->type)
  {
  case XML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
  case XML_DOCB_DOCUMENT_NODE:
#endif
  case XML_HTML_DOCUMENT_NODE:
  case XML_NAMESPACE_DECL:
    break;
  case XML_ATTRIBUTE_NODE:
    xdoc = (xmlDocPtr)((xmlAttrPtr) xnode->doc);
    break;
  default:
    xdoc = xnode->doc;
  }

  if (xdoc == NULL)
    return (Qnil);
  else if (xdoc->_private)
    return (VALUE) xdoc->_private;
  else
    return (Qnil);
}

/*
 * call-seq:
 *    node.to_s -> "string"
 *    node.to_s(:indent => true, :encoding => 'UTF-8', :level => 0) -> "string"
 *
 * Converts a node, and all of its children, to a string representation.
 * To include only the node's children, use the the XML::Node#inner_xml
 * method.
 *
 * You may provide an optional hash table to control how the string is 
 * generated.  Valid options are:
 * 
 * :indent - Specifies if the string should be indented.  The default value
 * is true.  Note that indentation is only added if both :indent is
 * true and XML.indent_tree_output is true.  If :indent is set to false,
 * then both indentation and line feeds are removed from the result.
 *
 * :level  - Specifies the indentation level.  The amount of indentation
 * is equal to the (level * number_spaces) + number_spaces, where libxml
 * defaults the number of spaces to 2.  Thus a level of 0 results in
 * 2 spaces, level 1 results in 4 spaces, level 2 results in 6 spaces, etc.
 *
 * :encoding - Specifies the output encoding of the string.  It
 * defaults to XML::Encoding::UTF8.  To change it, use one of the
 * XML::Encoding encoding constants. */

static VALUE rxml_node_to_s(int argc, VALUE *argv, VALUE self)
{
  VALUE result = Qnil;
  VALUE options = Qnil;
  xmlNodePtr xnode;
  xmlCharEncodingHandlerPtr encodingHandler;
  xmlOutputBufferPtr output;

  int level = 0;
  int indent = 1;
  const char *xencoding = "UTF-8";

  rb_scan_args(argc, argv, "01", &options);

  if (!NIL_P(options))
  {
    VALUE rencoding, rindent, rlevel;
    Check_Type(options, T_HASH);
    rencoding = rb_hash_aref(options, ID2SYM(rb_intern("encoding")));
    rindent = rb_hash_aref(options, ID2SYM(rb_intern("indent")));
    rlevel = rb_hash_aref(options, ID2SYM(rb_intern("level")));

    if (rindent == Qfalse)
      indent = 0;

    if (rlevel != Qnil)
      level = NUM2INT(rlevel);

    if (rencoding != Qnil)
    {
      xencoding = xmlGetCharEncodingName((xmlCharEncoding)NUM2INT(rencoding));
      if (!xencoding)
        rb_raise(rb_eArgError, "Unknown encoding value: %d", NUM2INT(rencoding));
    }
  }

  encodingHandler = xmlFindCharEncodingHandler(xencoding);
  output = xmlAllocOutputBuffer(encodingHandler);

  xnode = rxml_get_xnode(self);

  xmlNodeDumpOutput(output, xnode->doc, xnode, level, indent, xencoding);
  xmlOutputBufferFlush(output);

  if (output->conv)
    result = rxml_new_cstr((const char*) output->conv->content, xencoding);
  else
    result = rxml_new_cstr((const char*) output->buffer->content, xencoding);

  xmlOutputBufferClose(output);
  
  return result;
}


/*
 * call-seq:
 *    node.each -> XML::Node
 *
 * Iterates over this node's children, including text
 * nodes, element nodes, etc.  If you wish to iterate
 * only over child elements, use XML::Node#each_element.
 *
 *  doc = XML::Document.new('model/books.xml')
 *  doc.root.each {|node| puts node}
 */
static VALUE rxml_node_each(VALUE self)
{
  xmlNodePtr xnode;
  xmlNodePtr xcurrent;
  xnode = rxml_get_xnode(self);

  xcurrent = xnode->children;

  while (xcurrent)
  {
    /* The user could remove this node, so first stache
       away the next node. */
    xmlNodePtr xnext = xcurrent->next;

    rb_yield(rxml_node_wrap(xcurrent));
    xcurrent = xnext;
  }
  return Qnil;
}

/*
 * call-seq:
 *    node.empty? -> (true|false)
 *
 * Determine whether this node is an empty or whitespace only text-node.
 */
static VALUE rxml_node_empty_q(VALUE self)
{
  xmlNodePtr xnode;
  xnode = rxml_get_xnode(self);
  if (xnode == NULL)
    return (Qnil);

  return ((xmlIsBlankNode(xnode) == 1) ? Qtrue : Qfalse);
}


/*
 * call-seq:
 *    node.eql?(other_node) => (true|false)
 *
 * Test equality between the two nodes. Two nodes are equal
 * if they are the same node or have the same XML representation.*/
static VALUE rxml_node_eql_q(VALUE self, VALUE other)
{
  if(self == other)
  {
    return Qtrue;
  }
  else if (NIL_P(other))
  {
    return Qfalse;
  }
  else
  {
    VALUE self_xml;
    VALUE other_xml;

    if (rb_obj_is_kind_of(other, cXMLNode) == Qfalse)
      rb_raise(rb_eTypeError, "Nodes can only be compared against other nodes");

    self_xml = rxml_node_to_s(0, NULL, self);
    other_xml = rxml_node_to_s(0, NULL, other);
    return(rb_funcall(self_xml, rb_intern("=="), 1, other_xml));
  }
}

/*
 * call-seq:
 *    node.lang -> "string"
 *
 * Obtain the language set for this node, if any.
 * This is set in XML via the xml:lang attribute.
 */
static VALUE rxml_node_lang_get(VALUE self)
{
  xmlNodePtr xnode;
  xmlChar *lang;
  VALUE result = Qnil;

  xnode = rxml_get_xnode(self);
  lang = xmlNodeGetLang(xnode);

  if (lang)
  {
    result = rxml_new_cstr((const char*) lang, NULL);
    xmlFree(lang);
  }

  return (result);
}

// TODO node_lang_set should support setting back to nil

/*
 * call-seq:
 *    node.lang = "string"
 *
 * Set the language for this node. This affects the value
 * of the xml:lang attribute.
 */
static VALUE rxml_node_lang_set(VALUE self, VALUE lang)
{
  xmlNodePtr xnode;

  Check_Type(lang, T_STRING);
  xnode = rxml_get_xnode(self);
  xmlNodeSetLang(xnode, (xmlChar*) StringValuePtr(lang));

  return (Qtrue);
}

/*
 * call-seq:
 *    node.last -> XML::Node
 *
 * Obtain the last child node of this node, if any.
 */
static VALUE rxml_node_last_get(VALUE self)
{
  xmlNodePtr xnode;

  xnode = rxml_get_xnode(self);

  if (xnode->last)
    return (rxml_node_wrap(xnode->last));
  else
    return (Qnil);
}

/*
 * call-seq:
 *    node.line_num -> num
 *
 * Obtain the line number (in the XML document) that this
 * node was read from. If +default_line_numbers+ is set
 * false (the default), this method returns zero.
 */
static VALUE rxml_node_line_num(VALUE self)
{
  xmlNodePtr xnode;
  long line_num;
  xnode = rxml_get_xnode(self);

  if (!xmlLineNumbersDefaultValue)
    rb_warn(
        "Line numbers were not retained: use XML::Parser::default_line_numbers=true");

  line_num = xmlGetLineNo(xnode);
  if (line_num == -1)
    return (Qnil);
  else
    return (INT2NUM((long) line_num));
}

/*
 * call-seq:
 *    node.xlink? -> (true|false)
 *
 * Determine whether this node is an xlink node.
 */
static VALUE rxml_node_xlink_q(VALUE self)
{
  xmlNodePtr xnode;
  xlinkType xlt;

  xnode = rxml_get_xnode(self);
  xlt = xlinkIsLink(xnode->doc, xnode);

  if (xlt == XLINK_TYPE_NONE)
    return (Qfalse);
  else
    return (Qtrue);
}

/*
 * call-seq:
 *    node.xlink_type -> num
 *
 * Obtain the type identifier for this xlink, if applicable.
 * If this is not an xlink node (see +xlink?+), will return
 * nil.
 */
static VALUE rxml_node_xlink_type(VALUE self)
{
  xmlNodePtr xnode;
  xlinkType xlt;

  xnode = rxml_get_xnode(self);
  xlt = xlinkIsLink(xnode->doc, xnode);

  if (xlt == XLINK_TYPE_NONE)
    return (Qnil);
  else
    return (INT2NUM(xlt));
}

/*
 * call-seq:
 *    node.xlink_type_name -> "string"
 *
 * Obtain the type name for this xlink, if applicable.
 * If this is not an xlink node (see +xlink?+), will return
 * nil.
 */
static VALUE rxml_node_xlink_type_name(VALUE self)
{
  xmlNodePtr xnode;
  xlinkType xlt;

  xnode = rxml_get_xnode(self);
  xlt = xlinkIsLink(xnode->doc, xnode);

  switch (xlt)
  {
  case XLINK_TYPE_NONE:
    return (Qnil);
  case XLINK_TYPE_SIMPLE:
    return (rxml_new_cstr("simple", NULL));
  case XLINK_TYPE_EXTENDED:
    return (rxml_new_cstr("extended", NULL));
  case XLINK_TYPE_EXTENDED_SET:
    return (rxml_new_cstr("extended_set", NULL));
  default:
    rb_fatal("Unknowng xlink type, %d", xlt);
  }
}

/*
 * call-seq:
 *    node.name -> "string"
 *
 * Obtain this node's name.
 */
static VALUE rxml_node_name_get(VALUE self)
{
  xmlNodePtr xnode;
  const xmlChar *name;

  xnode = rxml_get_xnode(self);

  switch (xnode->type)
  {
  case XML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
    case XML_DOCB_DOCUMENT_NODE:
#endif
  case XML_HTML_DOCUMENT_NODE:
  {
    xmlDocPtr doc = (xmlDocPtr) xnode;
    name = doc->URL;
    break;
  }
  case XML_ATTRIBUTE_NODE:
  {
    xmlAttrPtr attr = (xmlAttrPtr) xnode;
    name = attr->name;
    break;
  }
  case XML_NAMESPACE_DECL:
  {
    xmlNsPtr ns = (xmlNsPtr) xnode;
    name = ns->prefix;
    break;
  }
  default:
    name = xnode->name;
    break;
  }

  if (xnode->name == NULL)
    return (Qnil);
  else
    return (rxml_new_cstr((const char*) name, NULL));
}

/*
 * call-seq:
 *    node.name = "string"
 *
 * Set this node's name.
 */
static VALUE rxml_node_name_set(VALUE self, VALUE name)
{
  xmlNodePtr xnode;
  const xmlChar *xname;

  Check_Type(name, T_STRING);
  xnode = rxml_get_xnode(self);
  xname = (const xmlChar*)StringValuePtr(name);

	/* Note: calling xmlNodeSetName() for a text node is ignored by libXML. */
  xmlNodeSetName(xnode, xname);

  return (Qtrue);
}

/*
 * call-seq:
 *    node.next -> XML::Node
 *
 * Returns the next sibling node if one exists.
 */
static VALUE rxml_node_next_get(VALUE self)
{
  xmlNodePtr xnode;

  xnode = rxml_get_xnode(self);

  if (xnode->next)
    return (rxml_node_wrap(xnode->next));
  else
    return (Qnil);
}

/*
 * call-seq:
 *    curr_node.next = node
 *
 * Adds the specified node as the next sibling of the current node.
 * If the node already exists in the document, it is first removed
 * from its existing context.  Any adjacent text nodes will be 
 * merged together, meaning the returned node may be different 
 * than the original node.
 */
static VALUE rxml_node_next_set(VALUE self, VALUE next)
{
  return rxml_node_modify_dom(self, next, xmlAddNextSibling);
}

/*
 * call-seq:
 *    node.parent -> XML::Node
 *
 * Obtain this node's parent node, if any.
 */
static VALUE rxml_node_parent_get(VALUE self)
{
  xmlNodePtr xnode;

  xnode = rxml_get_xnode(self);

  if (xnode->parent)
    return (rxml_node_wrap(xnode->parent));
  else
    return (Qnil);
}

/*
 * call-seq:
 *    node.path -> path
 *
 * Obtain this node's path.
 */
static VALUE rxml_node_path(VALUE self)
{
  xmlNodePtr xnode;
  xmlChar *path;

  xnode = rxml_get_xnode(self);
  path = xmlGetNodePath(xnode);

  if (path == NULL)
    return (Qnil);
  else
    return (rxml_new_cstr((const char*) path, NULL));
}

/*
 * call-seq:
 *    node.pointer -> XML::NodeSet
 *
 * Evaluates an XPointer expression relative to this node.
 */
static VALUE rxml_node_pointer(VALUE self, VALUE xptr_str)
{
  return (rxml_xpointer_point2(self, xptr_str));
}

/*
 * call-seq:
 *    node.prev -> XML::Node
 *
 * Obtain the previous sibling, if any.
 */
static VALUE rxml_node_prev_get(VALUE self)
{
  xmlNodePtr xnode;
  xmlNodePtr node;
  xnode = rxml_get_xnode(self);

  switch (xnode->type)
  {
  case XML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
    case XML_DOCB_DOCUMENT_NODE:
#endif
  case XML_HTML_DOCUMENT_NODE:
  case XML_NAMESPACE_DECL:
    node = NULL;
    break;
  case XML_ATTRIBUTE_NODE:
  {
    xmlAttrPtr attr = (xmlAttrPtr) xnode;
    node = (xmlNodePtr) attr->prev;
  }
    break;
  default:
    node = xnode->prev;
    break;
  }

  if (node == NULL)
    return (Qnil);
  else
    return (rxml_node_wrap(node));
}

/*
 * call-seq:
 *    curr_node.prev = node
 *
 * Adds the specified node as the previous sibling of the current node.
 * If the node already exists in the document, it is first removed
 * from its existing context.  Any adjacent text nodes will be 
 * merged together, meaning the returned node may be different 
 * than the original node.
 */
static VALUE rxml_node_prev_set(VALUE self, VALUE prev)
{
  return rxml_node_modify_dom(self, prev, xmlAddPrevSibling);
}

/*
 * call-seq:
 *    node.attributes -> attributes
 *
 * Returns the XML::Attributes for this node.
 */
static VALUE rxml_node_attributes_get(VALUE self)
{
  xmlNodePtr xnode;

  xnode = rxml_get_xnode(self);
  return rxml_attributes_new(xnode);
}

/*
 * call-seq:
 *    node.property("name") -> "string"
 *    node["name"]          -> "string"
 *
 * Obtain the named property.
 */
static VALUE rxml_node_attribute_get(VALUE self, VALUE name)
{
  VALUE attributes = rxml_node_attributes_get(self);
  return rxml_attributes_attribute_get(attributes, name);
}

/*
 * call-seq:
 *    node["name"] = "string"
 *
 * Set the named property.
 */
static VALUE rxml_node_property_set(VALUE self, VALUE name, VALUE value)
{
  VALUE attributes = rxml_node_attributes_get(self);
  return rxml_attributes_attribute_set(attributes, name, value);
}

/*
 * call-seq:
 *    node.remove! -> node
 *
 * Removes this node and its children from the document tree by setting its document,
 * parent and siblings to nil.  You can add the returned node back into a document.
 * Otherwise, the node will be freed once any references to it go out of scope. 
 */

static VALUE rxml_node_remove_ex(VALUE self)
{
  xmlNodePtr xnode, xresult;
  xnode = rxml_get_xnode(self);

  /* First unlink the node from its parent. */
  xmlUnlinkNode(xnode);

  /* Now copy the node we want to remove and make the
     current Ruby object point to it.  We do this because
     a node has a number of dependencies on its parent
     document - its name (if using a dictionary), entities,
     namespaces, etc.  For a node to live on its own, it
     needs to get its own copies of this information.*/
  xresult = xmlDocCopyNode(xnode, NULL, 1);
  
  /* Now free the original node. */
  xmlFreeNode(xnode);

  /* Now wrap the new node */
  RDATA(self)->data = xresult;
  xresult->_private = (void*) self;

  /* Now return the removed node so the user can
     do something with it.*/
  return self;
}

/*
 * call-seq:
 *    curr_node.sibling = node
 *
 * Adds the specified node as the end of the current node's list
 * of siblings.  If the node already exists in the document, it 
 * is first removed from its existing context.  Any adjacent text
 * nodes will be  merged together, meaning the returned node may
 * be different than the original node.
 */
static VALUE rxml_node_sibling_set(VALUE self, VALUE sibling)
{
  return rxml_node_modify_dom(self, sibling, xmlAddSibling);
}

/*
 * call-seq:
 *    text_node.output_escaping?      -> (true|false)
 *    element_node.output_escaping?   -> (true|false|nil)
 *    attribute_node.output_escaping? -> (true|false|nil)
 *    other_node.output_escaping?     -> (nil)
 *
 * Determine whether this node escapes it's output or not.
 *
 * Text nodes return only +true+ or +false+.  Element and attribute nodes
 * examine their immediate text node children to determine the value.
 * Any other type of node always returns +nil+.
 *
 * If an element or attribute node has at least one immediate child text node 
 * and all the immediate text node children have the same +output_escaping?+
 * value, that value is returned.  Otherwise, +nil+ is returned.
 */
static VALUE rxml_node_output_escaping_q(VALUE self)
{
  xmlNodePtr xnode;
  xnode = rxml_get_xnode(self);

  switch (xnode->type) {
  case XML_TEXT_NODE:
    return xnode->name==xmlStringTextNoenc ? Qfalse : Qtrue;
  case XML_ELEMENT_NODE:
  case XML_ATTRIBUTE_NODE:
    {
      xmlNodePtr tmp = xnode->children;
      const xmlChar *match = NULL;

      /* Find the first text node and use it as the reference. */
      while (tmp && tmp->type != XML_TEXT_NODE)
        tmp = tmp->next;
      if (! tmp)
        return Qnil;
      match = tmp->name;

      /* Walk the remaining text nodes until we run out or one doesn't match. */
      while (tmp && (tmp->type != XML_TEXT_NODE || match == tmp->name))
        tmp = tmp->next;

      /* We're left with either the mismatched node or the aggregate result. */
      return tmp ? Qnil : (match==xmlStringTextNoenc ? Qfalse : Qtrue);
    }
    break;
  default:
    return Qnil;
  }
}

/*
 * call-seq:
 *    text_node.output_escaping = true|false
 *    element_node.output_escaping = true|false
 *    attribute_node.output_escaping = true|false
 *
 * Controls whether this text node or the immediate text node children of an
 * element or attribute node escapes their output.  Any other type of node
 * will simply ignore this operation.
 *
 * Text nodes which are added to an element or attribute node will be affected
 * by any previous setting of this property.
 */
static VALUE rxml_node_output_escaping_set(VALUE self, VALUE bool)
{
  xmlNodePtr xnode;
  xnode = rxml_get_xnode(self);

  switch (xnode->type) {
  case XML_TEXT_NODE:
    xnode->name = (bool!=Qfalse && bool!=Qnil) ? xmlStringText : xmlStringTextNoenc;
    break;
  case XML_ELEMENT_NODE:
  case XML_ATTRIBUTE_NODE:
    {
      const xmlChar *name = (bool!=Qfalse && bool!=Qnil) ? xmlStringText : xmlStringTextNoenc;
      xmlNodePtr tmp;
      for (tmp = xnode->children; tmp; tmp = tmp->next)
        if (tmp->type == XML_TEXT_NODE)
          tmp->name = name;
    }
    break;
  default:
    return Qnil;
  }

  return (bool!=Qfalse && bool!=Qnil) ? Qtrue : Qfalse;
}

/*
 * call-seq:
 *    node.space_preserve -> (true|false)
 *
 * Determine whether this node preserves whitespace.
 */
static VALUE rxml_node_space_preserve_get(VALUE self)
{
  xmlNodePtr xnode;

  xnode = rxml_get_xnode(self);
  return (INT2NUM(xmlNodeGetSpacePreserve(xnode)));
}

/*
 * call-seq:
 *    node.space_preserve = true|false
 *
 * Control whether this node preserves whitespace.
 */
static VALUE rxml_node_space_preserve_set(VALUE self, VALUE bool)
{
  xmlNodePtr xnode;
  xnode = rxml_get_xnode(self);

  if (TYPE(bool) == T_FALSE)
    xmlNodeSetSpacePreserve(xnode, 0);
  else
    xmlNodeSetSpacePreserve(xnode, 1);

  return (Qnil);
}

/*
 * call-seq:
 *    node.type -> num
 *
 * Obtain this node's type identifier.
 */
static VALUE rxml_node_type(VALUE self)
{
  xmlNodePtr xnode;
  xnode = rxml_get_xnode(self);
  return (INT2NUM(xnode->type));
}

/*
 * call-seq:
 *    node.copy -> XML::Node
 *
 * Creates a copy of this node.  To create a
 * shallow copy set the deep parameter to false.
 * To create a deep copy set the deep parameter
 * to true.
 *
 */
static VALUE rxml_node_copy(VALUE self, VALUE deep)
{
  xmlNodePtr xnode;
  xmlNodePtr xcopy;
  int recursive = (deep == Qnil || deep == Qfalse) ? 0 : 1;
  xnode = rxml_get_xnode(self);

  xcopy = xmlCopyNode(xnode, recursive);

  if (xcopy)
    return rxml_node_wrap(xcopy);
  else
    return Qnil;
}

void rxml_init_node(void)
{
  /* Register callback for main thread */
  xmlDeregisterNodeDefault(rxml_node_deregisterNode);

  /* Register callback for all other threads */
  xmlThrDefDeregisterNodeDefault(rxml_node_deregisterNode);

  cXMLNode = rb_define_class_under(mXML, "Node", rb_cObject);

  rb_define_const(cXMLNode, "SPACE_DEFAULT", INT2NUM(0));
  rb_define_const(cXMLNode, "SPACE_PRESERVE", INT2NUM(1));
  rb_define_const(cXMLNode, "SPACE_NOT_INHERIT", INT2NUM(-1));
  rb_define_const(cXMLNode, "XLINK_ACTUATE_AUTO", INT2NUM(1));
  rb_define_const(cXMLNode, "XLINK_ACTUATE_NONE", INT2NUM(0));
  rb_define_const(cXMLNode, "XLINK_ACTUATE_ONREQUEST", INT2NUM(2));
  rb_define_const(cXMLNode, "XLINK_SHOW_EMBED", INT2NUM(2));
  rb_define_const(cXMLNode, "XLINK_SHOW_NEW", INT2NUM(1));
  rb_define_const(cXMLNode, "XLINK_SHOW_NONE", INT2NUM(0));
  rb_define_const(cXMLNode, "XLINK_SHOW_REPLACE", INT2NUM(3));
  rb_define_const(cXMLNode, "XLINK_TYPE_EXTENDED", INT2NUM(2));
  rb_define_const(cXMLNode, "XLINK_TYPE_EXTENDED_SET", INT2NUM(3));
  rb_define_const(cXMLNode, "XLINK_TYPE_NONE", INT2NUM(0));
  rb_define_const(cXMLNode, "XLINK_TYPE_SIMPLE", INT2NUM(1));

  rb_define_const(cXMLNode, "ELEMENT_NODE", INT2FIX(XML_ELEMENT_NODE));
  rb_define_const(cXMLNode, "ATTRIBUTE_NODE", INT2FIX(XML_ATTRIBUTE_NODE));
  rb_define_const(cXMLNode, "TEXT_NODE", INT2FIX(XML_TEXT_NODE));
  rb_define_const(cXMLNode, "CDATA_SECTION_NODE", INT2FIX(XML_CDATA_SECTION_NODE));
  rb_define_const(cXMLNode, "ENTITY_REF_NODE", INT2FIX(XML_ENTITY_REF_NODE));
  rb_define_const(cXMLNode, "ENTITY_NODE", INT2FIX(XML_ENTITY_NODE));
  rb_define_const(cXMLNode, "PI_NODE", INT2FIX(XML_PI_NODE));
  rb_define_const(cXMLNode, "COMMENT_NODE", INT2FIX(XML_COMMENT_NODE));
  rb_define_const(cXMLNode, "DOCUMENT_NODE", INT2FIX(XML_DOCUMENT_NODE));
  rb_define_const(cXMLNode, "DOCUMENT_TYPE_NODE", INT2FIX(XML_DOCUMENT_TYPE_NODE));
  rb_define_const(cXMLNode, "DOCUMENT_FRAG_NODE", INT2FIX(XML_DOCUMENT_FRAG_NODE));
  rb_define_const(cXMLNode, "NOTATION_NODE", INT2FIX(XML_NOTATION_NODE));
  rb_define_const(cXMLNode, "HTML_DOCUMENT_NODE", INT2FIX(XML_HTML_DOCUMENT_NODE));
  rb_define_const(cXMLNode, "DTD_NODE", INT2FIX(XML_DTD_NODE));
  rb_define_const(cXMLNode, "ELEMENT_DECL", INT2FIX(XML_ELEMENT_DECL));
  rb_define_const(cXMLNode, "ATTRIBUTE_DECL", INT2FIX(XML_ATTRIBUTE_DECL));
  rb_define_const(cXMLNode, "ENTITY_DECL", INT2FIX(XML_ENTITY_DECL));
  rb_define_const(cXMLNode, "NAMESPACE_DECL", INT2FIX(XML_NAMESPACE_DECL));
  rb_define_const(cXMLNode, "XINCLUDE_START", INT2FIX(XML_XINCLUDE_START));
  rb_define_const(cXMLNode, "XINCLUDE_END", INT2FIX(XML_XINCLUDE_END));

#ifdef LIBXML_DOCB_ENABLED
  rb_define_const(cXMLNode, "DOCB_DOCUMENT_NODE", INT2FIX(XML_DOCB_DOCUMENT_NODE));
#else
  rb_define_const(cXMLNode, "DOCB_DOCUMENT_NODE", Qnil);
#endif

  rb_define_singleton_method(cXMLNode, "new_cdata", rxml_node_new_cdata, -1);
  rb_define_singleton_method(cXMLNode, "new_comment", rxml_node_new_comment, -1);
  rb_define_singleton_method(cXMLNode, "new_text", rxml_node_new_text, 1);

  /* Initialization */
  rb_define_alloc_func(cXMLNode, rxml_node_alloc);
  rb_define_method(cXMLNode, "initialize", rxml_node_initialize, -1);

  /* Traversal */
  rb_include_module(cXMLNode, rb_mEnumerable);
  rb_define_method(cXMLNode, "[]", rxml_node_attribute_get, 1);
  rb_define_method(cXMLNode, "each", rxml_node_each, 0);
  rb_define_method(cXMLNode, "first", rxml_node_first_get, 0);
  rb_define_method(cXMLNode, "last", rxml_node_last_get, 0);
  rb_define_method(cXMLNode, "next", rxml_node_next_get, 0);
  rb_define_method(cXMLNode, "parent", rxml_node_parent_get, 0);
  rb_define_method(cXMLNode, "prev", rxml_node_prev_get, 0);

  /* Modification */
  rb_define_method(cXMLNode, "[]=", rxml_node_property_set, 2);
  rb_define_method(cXMLNode, "<<", rxml_node_content_add, 1);
  rb_define_method(cXMLNode, "sibling=", rxml_node_sibling_set, 1);
  rb_define_method(cXMLNode, "next=", rxml_node_next_set, 1);
  rb_define_method(cXMLNode, "prev=", rxml_node_prev_set, 1);

  /* Rest of the node api */
  rb_define_method(cXMLNode, "attributes", rxml_node_attributes_get, 0);
  rb_define_method(cXMLNode, "base_uri", rxml_node_base_uri_get, 0);
  rb_define_method(cXMLNode, "base_uri=", rxml_node_base_uri_set, 1);
  rb_define_method(cXMLNode, "blank?", rxml_node_empty_q, 0);
  rb_define_method(cXMLNode, "copy", rxml_node_copy, 1);
  rb_define_method(cXMLNode, "content", rxml_node_content_get, 0);
  rb_define_method(cXMLNode, "content=", rxml_node_content_set, 1);
  rb_define_method(cXMLNode, "content_stripped", rxml_node_content_stripped_get, 0);
  rb_define_method(cXMLNode, "debug", rxml_node_debug, 0);
  rb_define_method(cXMLNode, "doc", rxml_node_doc, 0);
  rb_define_method(cXMLNode, "empty?", rxml_node_empty_q, 0);
  rb_define_method(cXMLNode, "eql?", rxml_node_eql_q, 1);
  rb_define_method(cXMLNode, "lang", rxml_node_lang_get, 0);
  rb_define_method(cXMLNode, "lang=", rxml_node_lang_set, 1);
  rb_define_method(cXMLNode, "line_num", rxml_node_line_num, 0);
  rb_define_method(cXMLNode, "name", rxml_node_name_get, 0);
  rb_define_method(cXMLNode, "name=", rxml_node_name_set, 1);
  rb_define_method(cXMLNode, "node_type", rxml_node_type, 0);
  rb_define_method(cXMLNode, "output_escaping?", rxml_node_output_escaping_q, 0);
  rb_define_method(cXMLNode, "output_escaping=", rxml_node_output_escaping_set, 1);
  rb_define_method(cXMLNode, "path", rxml_node_path, 0);
  rb_define_method(cXMLNode, "pointer", rxml_node_pointer, 1);
  rb_define_method(cXMLNode, "remove!", rxml_node_remove_ex, 0);
  rb_define_method(cXMLNode, "space_preserve", rxml_node_space_preserve_get, 0);
  rb_define_method(cXMLNode, "space_preserve=", rxml_node_space_preserve_set, 1);
  rb_define_method(cXMLNode, "to_s", rxml_node_to_s, -1);
  rb_define_method(cXMLNode, "xlink?", rxml_node_xlink_q, 0);
  rb_define_method(cXMLNode, "xlink_type", rxml_node_xlink_type, 0);
  rb_define_method(cXMLNode, "xlink_type_name", rxml_node_xlink_type_name, 0);

  rb_define_alias(cXMLNode, "==", "eql?");
}
