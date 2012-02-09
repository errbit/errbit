/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"
#include "ruby_xml_sax2_handler.h"


VALUE cbidOnCdataBlock;
VALUE cbidOnCharacters;
VALUE cbidOnComment;
VALUE cbidOnEndDocument;
VALUE cbidOnEndElement;
VALUE cbidOnEndElementNs;
VALUE cbidOnExternalSubset;
VALUE cbidOnHasExternalSubset;
VALUE cbidOnHasInternalSubset;
VALUE cbidOnInternalSubset;
VALUE cbidOnIsStandalone;
VALUE cbidOnError;
VALUE cbidOnProcessingInstruction;
VALUE cbidOnReference;
VALUE cbidOnStartElement;
VALUE cbidOnStartElementNs;
VALUE cbidOnStartDocument;

/* ======  Callbacks  =========== */
static void cdata_block_callback(void *ctx,
const char *value, int len)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    rb_funcall(handler, cbidOnCdataBlock,1,rb_str_new(value, len));
  }
}

static void characters_callback(void *ctx,
const char *chars, int len)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    VALUE rchars = rb_str_new(chars, len);
    rb_funcall(handler, cbidOnCharacters, 1, rchars);
  }
}

static void comment_callback(void *ctx,
const char *msg)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    rb_funcall(handler, cbidOnComment,1,rb_str_new2(msg));
  }
}

static void end_document_callback(void *ctx)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    rb_funcall(handler, cbidOnEndDocument, 0);
  }
}

static void end_element_ns_callback(void *ctx,
  					                        const xmlChar *xlocalname, const xmlChar *xprefix, const xmlChar *xURI)
{
  VALUE handler = (VALUE) ctx;

  if (handler == Qnil)
    return;

  /* Call end element for old-times sake */
  if (rb_respond_to(handler, cbidOnEndElement))
  {
    VALUE name;
    if (xprefix)
    {
      name = rb_str_new2(xprefix);
      rb_str_cat2(name, ":"); 
      rb_str_cat2(name, xlocalname); 
    }
    else
    {
      name = rb_str_new2(xlocalname);
    }
    rb_funcall(handler, cbidOnEndElement, 1, name);
  }

  rb_funcall(handler, cbidOnEndElementNs, 3, 
             rb_str_new2(xlocalname),
             xprefix ? rb_str_new2(xprefix) : Qnil,
             xURI ? rb_str_new2(xURI) : Qnil);
}

static void external_subset_callback(void *ctx, const char *name, const char *extid, const char *sysid)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    VALUE rname = name ? rb_str_new2(name) : Qnil;
    VALUE rextid = extid ? rb_str_new2(extid) : Qnil;
    VALUE rsysid = sysid ? rb_str_new2(sysid) : Qnil;
    rb_funcall(handler, cbidOnExternalSubset, 3, rname, rextid, rsysid);
  }
}

static void has_external_subset_callback(void *ctx)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    rb_funcall(handler, cbidOnHasExternalSubset, 0);
  }
}

static void has_internal_subset_callback(void *ctx)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    rb_funcall(handler, cbidOnHasInternalSubset, 0);
  }
}

static void internal_subset_callback(void *ctx, const char *name, const char *extid, const char *sysid)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    VALUE rname = name ? rb_str_new2(name) : Qnil;
    VALUE rextid = extid ? rb_str_new2(extid) : Qnil;
    VALUE rsysid = sysid ? rb_str_new2(sysid) : Qnil;
    rb_funcall(handler, cbidOnInternalSubset, 3, rname, rextid, rsysid);
  }
}

static void is_standalone_callback(void *ctx)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    rb_funcall(handler, cbidOnIsStandalone,0);
  }
}

static void processing_instruction_callback(void *ctx, const char *target, const char *data)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    VALUE rtarget = target ? rb_str_new2(target) : Qnil;
    VALUE rdata = data ? rb_str_new2(data) : Qnil;
    rb_funcall(handler, cbidOnProcessingInstruction, 2, rtarget, rdata);
  }
}

static void reference_callback(void *ctx, const char *name)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    rb_funcall(handler, cbidOnReference,1,rb_str_new2(name));
  }
}

static void start_document_callback(void *ctx)
{
  VALUE handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    rb_funcall(handler, cbidOnStartDocument, 0);
  }
}

static void start_element_ns_callback(void *ctx, 
                                      const xmlChar *xlocalname, const xmlChar *xprefix, const xmlChar *xURI,
                            					int nb_namespaces, const xmlChar **xnamespaces,
					                            int nb_attributes, int nb_defaulted, const xmlChar **xattributes)
{
  VALUE handler = (VALUE) ctx;
  VALUE attributes = rb_hash_new();
  VALUE namespaces = rb_hash_new();

  if (handler == Qnil)
    return;

  if (xattributes)
  {
    /* Each attribute is an array of [localname, prefix, URI, value, end] */
    int i;
    for (i = 0;i < nb_attributes * 5; i+=5) 
    {
      VALUE attrName = rb_str_new2(xattributes[i+0]);
      VALUE attrValue = rb_str_new(xattributes[i+3], xattributes[i+4] - xattributes[i+3]);
      /* VALUE attrPrefix = xattributes[i+1] ? rb_str_new2(xattributes[i+1]) : Qnil;
         VALUE attrURI = xattributes[i+2] ? rb_str_new2(xattributes[i+2]) : Qnil; */

      rb_hash_aset(attributes, attrName, attrValue);
    }
  }

  if (xnamespaces)
  {
    int i;
    for (i = 0;i < nb_namespaces * 2; i+=2) 
    {
      VALUE nsPrefix = xnamespaces[i+0] ? rb_str_new2(xnamespaces[i+0]) : Qnil;
      VALUE nsURI = xnamespaces[i+1] ? rb_str_new2(xnamespaces[i+1]) : Qnil;
      rb_hash_aset(namespaces, nsPrefix, nsURI);
    }
  }

  /* Call start element for old-times sake */
  if (rb_respond_to(handler, cbidOnStartElement))
  {
    VALUE name;
    if (xprefix)
    {
      name = rb_str_new2(xprefix);
      rb_str_cat2(name, ":"); 
      rb_str_cat2(name, xlocalname); 
    }
    else
    {
      name = rb_str_new2(xlocalname);
    }
    rb_funcall(handler, cbidOnStartElement, 2, name, attributes);
  }

  rb_funcall(handler, cbidOnStartElementNs, 5, 
             rb_str_new2(xlocalname),
             attributes,
             xprefix ? rb_str_new2(xprefix) : Qnil,
             xURI ? rb_str_new2(xURI) : Qnil,
             namespaces);
}

static void structured_error_callback(void *ctx, xmlErrorPtr xerror)
{
  /* Older versions of Libxml will pass a NULL context from the sax parser.  Fixed on
     Feb 23, 2011.  See:

     http://git.gnome.org/browse/libxml2/commit/?id=241d4a1069e6bedd0ee2295d7b43858109c1c6d1 */

  VALUE handler;

  #if LIBXML_VERSION <= 20708
    xmlParserCtxtPtr ctxt = (xmlParserCtxt*)(xerror->ctxt);
    ctx = ctxt->userData;
  #endif

  handler = (VALUE) ctx;

  if (handler != Qnil)
  {
    VALUE error = rxml_error_wrap(xerror);
    rb_funcall(handler, cbidOnError, 1, error);
  }
}

/* ======  Handler  =========== */
xmlSAXHandler rxml_sax_handler = {
  (internalSubsetSAXFunc) internal_subset_callback,
  (isStandaloneSAXFunc) is_standalone_callback,
  (hasInternalSubsetSAXFunc) has_internal_subset_callback,
  (hasExternalSubsetSAXFunc) has_external_subset_callback,
  0, /* resolveEntity */
  0, /* getEntity */
  0, /* entityDecl */
  0, /* notationDecl */
  0, /* attributeDecl */
  0, /* elementDecl */
  0, /* unparsedEntityDecl */
  0, /* setDocumentLocator */
  (startDocumentSAXFunc) start_document_callback,
  (endDocumentSAXFunc) end_document_callback,
  0, /* Use start_element_ns_callback instead */
  0, /* Use end_element_ns_callback instead */
  (referenceSAXFunc) reference_callback,
  (charactersSAXFunc) characters_callback,
  0, /* ignorableWhitespace */
  (processingInstructionSAXFunc) processing_instruction_callback,
  (commentSAXFunc) comment_callback,
  0, /* xmlStructuredErrorFunc is used instead */
  0, /* xmlStructuredErrorFunc is used instead */
  0, /* xmlStructuredErrorFunc is used instead */
  0, /* xmlGetParameterEntity */
  (cdataBlockSAXFunc) cdata_block_callback,
  (externalSubsetSAXFunc) external_subset_callback,
  XML_SAX2_MAGIC, /* force SAX2 */
  0, /* _private */
  (startElementNsSAX2Func) start_element_ns_callback,
  (endElementNsSAX2Func) end_element_ns_callback,
  (xmlStructuredErrorFunc) structured_error_callback
};

void rxml_init_sax2_handler(void)
{

  /* SaxCallbacks */
  cbidOnCdataBlock =            rb_intern("on_cdata_block");
  cbidOnCharacters =            rb_intern("on_characters");
  cbidOnComment =               rb_intern("on_comment");
  cbidOnEndDocument =           rb_intern("on_end_document");
  cbidOnEndElement =            rb_intern("on_end_element");
  cbidOnEndElementNs =          rb_intern("on_end_element_ns");
  cbidOnError =                 rb_intern("on_error");
  cbidOnExternalSubset =        rb_intern("on_external_subset");
  cbidOnHasExternalSubset =     rb_intern("on_has_external_subset");
  cbidOnHasInternalSubset =     rb_intern("on_has_internal_subset");
  cbidOnInternalSubset =        rb_intern("on_internal_subset");
  cbidOnIsStandalone =          rb_intern("on_is_standalone");
  cbidOnProcessingInstruction = rb_intern("on_processing_instruction");
  cbidOnReference =             rb_intern("on_reference");
  cbidOnStartElement =          rb_intern("on_start_element");
  cbidOnStartElementNs =        rb_intern("on_start_element_ns");
  cbidOnStartDocument =         rb_intern("on_start_document");
}
