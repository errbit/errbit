#include "ruby_libxml.h"

#include <libxml/xmlerror.h>

VALUE eXMLError;
static ID CALL_METHOD;
static ID ERROR_HANDLER_ID;

/*
 * Document-class: LibXML::XML::Error
 *
 * The XML::Error class exposes libxml errors as
 * standard Ruby exceptions.  When appropriate,
 * libxml-ruby will raise an exception - for example,
 * when parsing a non-well formed xml document.
 *
 * By default, warnings, errors and fatal errors that
 * libxml generates are printed to STDERR via the
 * XML::Error::VERBOSE_HANDLER proc.
 *
 * To disable this output you can install the quiet handler:
 *
 *   XML::Error.set_handler(&XML::Error::QUIET_HANDLER)
 *
 * Install your own handler:
 *
 *   XML::Error.set_handler do |error|
 *     puts error.to_s
 *   end
 *
 * Or remove all handlers:
 *
 *   XML::Error.reset_handler
 */

static void rxml_set_handler(VALUE self, VALUE block)
{
#ifdef RB_CVAR_SET_4ARGS
  rb_cvar_set(self, ERROR_HANDLER_ID, block, 0);
#else
  rb_cvar_set(self, ERROR_HANDLER_ID, block);
#endif
}

/*
 * call-seq:
 *    Error.set_error_handler {|error| ... }
 *
 * Registers a block that will be called with an instance of
 * XML::Error when libxml generates warning, error or fatal
 * error messages.
 */
static VALUE rxml_error_set_handler(VALUE self)
{
  VALUE block;

  if (rb_block_given_p() == Qfalse)
    rb_raise(rb_eRuntimeError, "No block given");

  block = rb_block_proc();

  /* Embed the block within the Error class to avoid it to be collected.
   Previous handler will be overwritten if it exists. */
  rxml_set_handler(self, block);

  return self;
}

/*
 * call-seq:
 *    Error.reset_error_handler
 *
 * Removes the current error handler. */
static VALUE rxml_error_reset_handler(VALUE self)
{
  rxml_set_handler(self, Qnil);
  return self;
}

VALUE rxml_error_wrap(xmlErrorPtr xerror)
{
  VALUE result = Qnil;

  if (xerror->message)
    result = rb_exc_new2(eXMLError, xerror->message);
  else
    result = rb_class_new_instance(0, NULL, eXMLError);

  rb_iv_set(result, "@domain", INT2NUM(xerror->domain));
  rb_iv_set(result, "@code", INT2NUM(xerror->code));
  rb_iv_set(result, "@level", INT2NUM(xerror->level));

  if (xerror->file)
    rb_iv_set(result, "@file", rb_str_new2(xerror->file));

  if (xerror->line)
    rb_iv_set(result, "@line", INT2NUM(xerror->line));

  if (xerror->str1)
    rb_iv_set(result, "@str1", rb_str_new2(xerror->str1));

  if (xerror->str2)
    rb_iv_set(result, "@str2", rb_str_new2(xerror->str2));

  if (xerror->str3)
    rb_iv_set(result, "@str3", rb_str_new2(xerror->str3));

  rb_iv_set(result, "@int1", INT2NUM(xerror->int1));
  rb_iv_set(result, "@int2", INT2NUM(xerror->int2));

  if (xerror->node)
  {
    /* Returning the original node is too dangerous because its 
       parent document is never returned to Ruby.  So return a 
       copy of the node, which does not belong to any document,
       and can free itself when Ruby calls its free method.  Note
       we just copy the node, and don't bother with the overhead
       of a recursive query. */
    xmlNodePtr xNode = xmlCopyNode((const xmlNodePtr)xerror->node, 2);
    VALUE node = rxml_node_wrap(xNode);
    rb_iv_set(result, "@node", node);
  }
  return result;
}

/* Hook that receives xml error message */
static void structuredErrorFunc(void *userData, xmlErrorPtr xerror)
{
  VALUE error = rxml_error_wrap(xerror);

  /* Wrap error up as Ruby object and send it off to ruby */
  VALUE block = rb_cvar_get(eXMLError, ERROR_HANDLER_ID);

  /* Now call global handler */
  if (block != Qnil)
  {
    rb_funcall(block, CALL_METHOD, 1, error);
  }
}

void rxml_raise(xmlErrorPtr xerror)
{
  /* Wrap error up as Ruby object and send it off to ruby */
  VALUE error = rxml_error_wrap(xerror);
  rb_exc_raise(error);
}

void rxml_init_error()
{
  CALL_METHOD = rb_intern("call");
  ERROR_HANDLER_ID = rb_intern("@@__error_handler_callback__");

  /* Intercept libxml error handlers */
  xmlSetStructuredErrorFunc(NULL, structuredErrorFunc);

  /* Error class */
  eXMLError = rb_define_class_under(mXML, "Error", rb_eStandardError);
  rb_define_singleton_method(eXMLError, "set_handler", rxml_error_set_handler, 0);
  rb_define_singleton_method(eXMLError, "reset_handler", rxml_error_reset_handler, 0);

  /* Ruby callback to receive errors - set it to nil by default. */
  rxml_set_handler(eXMLError, Qnil);

  /* Error attributes */
  rb_define_attr(eXMLError, "level", 1, 0);
  rb_define_attr(eXMLError, "domain", 1, 0);
  rb_define_attr(eXMLError, "code", 1, 0);
  rb_define_attr(eXMLError, "file", 1, 0);
  rb_define_attr(eXMLError, "line", 1, 0);
  rb_define_attr(eXMLError, "str1", 1, 0);
  rb_define_attr(eXMLError, "str2", 1, 0);
  rb_define_attr(eXMLError, "str3", 1, 0);
  rb_define_attr(eXMLError, "int1", 1, 0);
  rb_define_attr(eXMLError, "int2", 1, 0);
  rb_define_attr(eXMLError, "ctxt", 1, 0);
  rb_define_attr(eXMLError, "node", 1, 0);

  /* xml error levels */
  rb_define_const(eXMLError, "NONE", INT2NUM(XML_ERR_NONE));
  rb_define_const(eXMLError, "WARNING", INT2NUM(XML_ERR_WARNING));
  rb_define_const(eXMLError, "ERROR", INT2NUM(XML_ERR_ERROR));
  rb_define_const(eXMLError, "FATAL", INT2NUM(XML_ERR_FATAL));

  /* xml error domains */
  rb_define_const(eXMLError, "NO_ERROR", INT2NUM(XML_FROM_NONE));
  rb_define_const(eXMLError, "PARSER", INT2NUM(XML_FROM_PARSER));
  rb_define_const(eXMLError, "TREE", INT2NUM(XML_FROM_TREE));
  rb_define_const(eXMLError, "NAMESPACE", INT2NUM(XML_FROM_NAMESPACE));
  rb_define_const(eXMLError, "DTD", INT2NUM(XML_FROM_DTD));
  rb_define_const(eXMLError, "HTML", INT2NUM(XML_FROM_HTML));
  rb_define_const(eXMLError, "MEMORY", INT2NUM(XML_FROM_MEMORY));
  rb_define_const(eXMLError, "OUTPUT", INT2NUM(XML_FROM_OUTPUT));
  rb_define_const(eXMLError, "IO", INT2NUM(XML_FROM_IO));
  rb_define_const(eXMLError, "FTP", INT2NUM(XML_FROM_FTP));
  rb_define_const(eXMLError, "HTTP", INT2NUM(XML_FROM_HTTP));
  rb_define_const(eXMLError, "XINCLUDE", INT2NUM(XML_FROM_XINCLUDE));
  rb_define_const(eXMLError, "XPATH", INT2NUM(XML_FROM_XPATH));
  rb_define_const(eXMLError, "XPOINTER", INT2NUM(XML_FROM_XPOINTER));
  rb_define_const(eXMLError, "REGEXP", INT2NUM(XML_FROM_REGEXP));
  rb_define_const(eXMLError, "DATATYPE", INT2NUM(XML_FROM_DATATYPE));
  rb_define_const(eXMLError, "SCHEMASP", INT2NUM(XML_FROM_SCHEMASP));
  rb_define_const(eXMLError, "SCHEMASV", INT2NUM(XML_FROM_SCHEMASV));
  rb_define_const(eXMLError, "RELAXNGP", INT2NUM(XML_FROM_RELAXNGP));
  rb_define_const(eXMLError, "RELAXNGV", INT2NUM(XML_FROM_RELAXNGV));
  rb_define_const(eXMLError, "CATALOG", INT2NUM(XML_FROM_CATALOG));
  rb_define_const(eXMLError, "C14N", INT2NUM(XML_FROM_C14N));
  rb_define_const(eXMLError, "XSLT", INT2NUM(XML_FROM_XSLT));
  rb_define_const(eXMLError, "VALID", INT2NUM(XML_FROM_VALID));
  rb_define_const(eXMLError, "CHECK", INT2NUM(XML_FROM_CHECK));
  rb_define_const(eXMLError, "WRITER", INT2NUM(XML_FROM_WRITER));
#if LIBXML_VERSION >= 20621
  rb_define_const(eXMLError, "MODULE", INT2NUM(XML_FROM_MODULE));
#endif
#if LIBXML_VERSION >= 20632
  rb_define_const(eXMLError, "I18N", INT2NUM(XML_FROM_I18N));
  rb_define_const(eXMLError, "SCHEMATRONV", INT2NUM(XML_FROM_SCHEMATRONV));
#endif

  /* errors */
  rb_define_const(eXMLError, "OK", INT2NUM(XML_ERR_OK));
  rb_define_const(eXMLError, "INTERNAL_ERROR", INT2NUM(XML_ERR_INTERNAL_ERROR));
  rb_define_const(eXMLError, "NO_MEMORY", INT2NUM(XML_ERR_NO_MEMORY));
  rb_define_const(eXMLError, "DOCUMENT_START", INT2NUM(XML_ERR_DOCUMENT_START));
  rb_define_const(eXMLError, "DOCUMENT_EMPTY", INT2NUM(XML_ERR_DOCUMENT_EMPTY));
  rb_define_const(eXMLError, "DOCUMENT_END", INT2NUM(XML_ERR_DOCUMENT_END));
  rb_define_const(eXMLError, "INVALID_HEX_CHARREF", INT2NUM(XML_ERR_INVALID_HEX_CHARREF));
  rb_define_const(eXMLError, "INVALID_DEC_CHARREF", INT2NUM(XML_ERR_INVALID_DEC_CHARREF));
  rb_define_const(eXMLError, "INVALID_CHARREF", INT2NUM(XML_ERR_INVALID_CHARREF));
  rb_define_const(eXMLError, "INVALID_CHAR", INT2NUM(XML_ERR_INVALID_CHAR));
  rb_define_const(eXMLError, "CHARREF_AT_EOF", INT2NUM(XML_ERR_CHARREF_AT_EOF));
  rb_define_const(eXMLError, "CHARREF_IN_PROLOG", INT2NUM(XML_ERR_CHARREF_IN_PROLOG));
  rb_define_const(eXMLError, "CHARREF_IN_EPILOG", INT2NUM(XML_ERR_CHARREF_IN_EPILOG));
  rb_define_const(eXMLError, "CHARREF_IN_DTD", INT2NUM(XML_ERR_CHARREF_IN_DTD));
  rb_define_const(eXMLError, "ENTITYREF_AT_EOF", INT2NUM(XML_ERR_ENTITYREF_AT_EOF));
  rb_define_const(eXMLError, "ENTITYREF_IN_PROLOG", INT2NUM(XML_ERR_ENTITYREF_IN_PROLOG));
  rb_define_const(eXMLError, "ENTITYREF_IN_EPILOG", INT2NUM(XML_ERR_ENTITYREF_IN_EPILOG));
  rb_define_const(eXMLError, "ENTITYREF_IN_DTD", INT2NUM(XML_ERR_ENTITYREF_IN_DTD));
  rb_define_const(eXMLError, "PEREF_AT_EOF", INT2NUM(XML_ERR_PEREF_AT_EOF));
  rb_define_const(eXMLError, "PEREF_IN_PROLOG", INT2NUM(XML_ERR_PEREF_IN_PROLOG));
  rb_define_const(eXMLError, "PEREF_IN_EPILOG",INT2NUM(XML_ERR_PEREF_IN_EPILOG));
  rb_define_const(eXMLError, "PEREF_IN_INT_SUBSET", INT2NUM(XML_ERR_PEREF_IN_INT_SUBSET));
  rb_define_const(eXMLError, "ENTITYREF_NO_NAME", INT2NUM(XML_ERR_ENTITYREF_NO_NAME));
  rb_define_const(eXMLError, "ENTITYREF_SEMICOL_MISSING", INT2NUM(XML_ERR_ENTITYREF_SEMICOL_MISSING));
  rb_define_const(eXMLError, "PEREF_NO_NAME", INT2NUM(XML_ERR_PEREF_NO_NAME));
  rb_define_const(eXMLError, "PEREF_SEMICOL_MISSING", INT2NUM(XML_ERR_PEREF_SEMICOL_MISSING));
  rb_define_const(eXMLError, "UNDECLARED_ENTITY", INT2NUM(XML_ERR_UNDECLARED_ENTITY));
  rb_define_const(eXMLError, "XML_WAR_UNDECLARED_ENTITY", INT2NUM(XML_WAR_UNDECLARED_ENTITY));
  rb_define_const(eXMLError, "UNPARSED_ENTITY", INT2NUM(XML_ERR_UNPARSED_ENTITY));
  rb_define_const(eXMLError, "ENTITY_IS_EXTERNAL", INT2NUM(XML_ERR_ENTITY_IS_EXTERNAL));
  rb_define_const(eXMLError, "ENTITY_IS_PARAMETER", INT2NUM(XML_ERR_ENTITY_IS_PARAMETER));
  rb_define_const(eXMLError, "UNKNOWN_ENCODING", INT2NUM(XML_ERR_UNKNOWN_ENCODING));
  rb_define_const(eXMLError, "UNSUPPORTED_ENCODING", INT2NUM(XML_ERR_UNSUPPORTED_ENCODING));
  rb_define_const(eXMLError, "STRING_NOT_STARTED", INT2NUM(XML_ERR_STRING_NOT_STARTED));
  rb_define_const(eXMLError, "STRING_NOT_CLOSED", INT2NUM(XML_ERR_STRING_NOT_CLOSED));
  rb_define_const(eXMLError, "NS_DECL_ERROR", INT2NUM(XML_ERR_NS_DECL_ERROR));
  rb_define_const(eXMLError, "ENTITY_NOT_STARTED", INT2NUM(XML_ERR_ENTITY_NOT_STARTED));
  rb_define_const(eXMLError, "ENTITY_NOT_FINISHED", INT2NUM(XML_ERR_ENTITY_NOT_FINISHED));
  rb_define_const(eXMLError, "LT_IN_ATTRIBUTE", INT2NUM(XML_ERR_LT_IN_ATTRIBUTE));
  rb_define_const(eXMLError, "ATTRIBUTE_NOT_STARTED", INT2NUM(XML_ERR_ATTRIBUTE_NOT_STARTED));
  rb_define_const(eXMLError, "ATTRIBUTE_NOT_FINISHED", INT2NUM(XML_ERR_ATTRIBUTE_NOT_FINISHED));
  rb_define_const(eXMLError, "ATTRIBUTE_WITHOUT_VALUE", INT2NUM(XML_ERR_ATTRIBUTE_WITHOUT_VALUE));
  rb_define_const(eXMLError, "ATTRIBUTE_REDEFINED", INT2NUM(XML_ERR_ATTRIBUTE_REDEFINED));
  rb_define_const(eXMLError, "LITERAL_NOT_STARTED", INT2NUM(XML_ERR_LITERAL_NOT_STARTED));
  rb_define_const(eXMLError, "LITERAL_NOT_FINISHED", INT2NUM(XML_ERR_LITERAL_NOT_FINISHED));
  rb_define_const(eXMLError, "COMMENT_NOT_FINISHED", INT2NUM(XML_ERR_COMMENT_NOT_FINISHED));
  rb_define_const(eXMLError, "PI_NOT_STARTED", INT2NUM(XML_ERR_PI_NOT_STARTED));
  rb_define_const(eXMLError, "PI_NOT_FINISHED", INT2NUM(XML_ERR_PI_NOT_FINISHED));
  rb_define_const(eXMLError, "NOTATION_NOT_STARTED", INT2NUM(XML_ERR_NOTATION_NOT_STARTED));
  rb_define_const(eXMLError, "NOTATION_NOT_FINISHED", INT2NUM(XML_ERR_NOTATION_NOT_FINISHED));
  rb_define_const(eXMLError, "ATTLIST_NOT_STARTED", INT2NUM(XML_ERR_ATTLIST_NOT_STARTED));
  rb_define_const(eXMLError, "ATTLIST_NOT_FINISHED", INT2NUM(XML_ERR_ATTLIST_NOT_FINISHED));
  rb_define_const(eXMLError, "MIXED_NOT_STARTED", INT2NUM(XML_ERR_MIXED_NOT_STARTED));
  rb_define_const(eXMLError, "MIXED_NOT_FINISHED", INT2NUM(XML_ERR_MIXED_NOT_FINISHED));
  rb_define_const(eXMLError, "ELEMCONTENT_NOT_STARTED", INT2NUM(XML_ERR_ELEMCONTENT_NOT_STARTED));
  rb_define_const(eXMLError, "ELEMCONTENT_NOT_FINISHED", INT2NUM(XML_ERR_ELEMCONTENT_NOT_FINISHED));
  rb_define_const(eXMLError, "XMLDECL_NOT_STARTED", INT2NUM(XML_ERR_XMLDECL_NOT_STARTED));
  rb_define_const(eXMLError, "XMLDECL_NOT_FINISHED", INT2NUM(XML_ERR_XMLDECL_NOT_FINISHED));
  rb_define_const(eXMLError, "CONDSEC_NOT_STARTED", INT2NUM(XML_ERR_CONDSEC_NOT_STARTED));
  rb_define_const(eXMLError, "CONDSEC_NOT_FINISHED", INT2NUM(XML_ERR_CONDSEC_NOT_FINISHED));
  rb_define_const(eXMLError, "EXT_SUBSET_NOT_FINISHED", INT2NUM(XML_ERR_EXT_SUBSET_NOT_FINISHED));
  rb_define_const(eXMLError, "DOCTYPE_NOT_FINISHED", INT2NUM(XML_ERR_DOCTYPE_NOT_FINISHED));
  rb_define_const(eXMLError, "MISPLACED_CDATA_END", INT2NUM(XML_ERR_MISPLACED_CDATA_END));
  rb_define_const(eXMLError, "CDATA_NOT_FINISHED", INT2NUM(XML_ERR_CDATA_NOT_FINISHED));
  rb_define_const(eXMLError, "RESERVED_XML_NAME", INT2NUM(XML_ERR_RESERVED_XML_NAME));
  rb_define_const(eXMLError, "SPACE_REQUIRED", INT2NUM(XML_ERR_SPACE_REQUIRED));
  rb_define_const(eXMLError, "SEPARATOR_REQUIRED", INT2NUM(XML_ERR_SEPARATOR_REQUIRED));
  rb_define_const(eXMLError, "NMTOKEN_REQUIRED", INT2NUM(XML_ERR_NMTOKEN_REQUIRED));
  rb_define_const(eXMLError, "NAME_REQUIRED", INT2NUM(XML_ERR_NAME_REQUIRED));
  rb_define_const(eXMLError, "PCDATA_REQUIRED", INT2NUM(XML_ERR_PCDATA_REQUIRED));
  rb_define_const(eXMLError, "URI_REQUIRED", INT2NUM(XML_ERR_URI_REQUIRED));
  rb_define_const(eXMLError, "PUBID_REQUIRED", INT2NUM(XML_ERR_PUBID_REQUIRED));
  rb_define_const(eXMLError, "LT_REQUIRED", INT2NUM(XML_ERR_LT_REQUIRED));
  rb_define_const(eXMLError, "GT_REQUIRED", INT2NUM(XML_ERR_GT_REQUIRED));
  rb_define_const(eXMLError, "LTSLASH_REQUIRED", INT2NUM(XML_ERR_LTSLASH_REQUIRED));
  rb_define_const(eXMLError, "EQUAL_REQUIRED", INT2NUM(XML_ERR_EQUAL_REQUIRED));
  rb_define_const(eXMLError, "TAG_NAME_MISMATCH", INT2NUM(XML_ERR_TAG_NAME_MISMATCH));
  rb_define_const(eXMLError, "TAG_NOT_FINISHED", INT2NUM(XML_ERR_TAG_NOT_FINISHED));
  rb_define_const(eXMLError, "STANDALONE_VALUE", INT2NUM(XML_ERR_STANDALONE_VALUE));
  rb_define_const(eXMLError, "ENCODING_NAME", INT2NUM(XML_ERR_ENCODING_NAME));
  rb_define_const(eXMLError, "HYPHEN_IN_COMMENT", INT2NUM(XML_ERR_HYPHEN_IN_COMMENT));
  rb_define_const(eXMLError, "INVALID_ENCODING", INT2NUM(XML_ERR_INVALID_ENCODING));
  rb_define_const(eXMLError, "EXT_ENTITY_STANDALONE", INT2NUM(XML_ERR_EXT_ENTITY_STANDALONE));
  rb_define_const(eXMLError, "CONDSEC_INVALID", INT2NUM(XML_ERR_CONDSEC_INVALID));
  rb_define_const(eXMLError, "VALUE_REQUIRED", INT2NUM(XML_ERR_VALUE_REQUIRED));
  rb_define_const(eXMLError, "NOT_WELL_BALANCED", INT2NUM(XML_ERR_NOT_WELL_BALANCED));
  rb_define_const(eXMLError, "EXTRA_CONTENT", INT2NUM(XML_ERR_EXTRA_CONTENT));
  rb_define_const(eXMLError, "ENTITY_CHAR_ERROR", INT2NUM(XML_ERR_ENTITY_CHAR_ERROR));
  rb_define_const(eXMLError, "ENTITY_PE_INTERNAL", INT2NUM(XML_ERR_ENTITY_PE_INTERNAL));
  rb_define_const(eXMLError, "ENTITY_LOOP", INT2NUM(XML_ERR_ENTITY_LOOP));
  rb_define_const(eXMLError, "ENTITY_BOUNDARY", INT2NUM(XML_ERR_ENTITY_BOUNDARY));
  rb_define_const(eXMLError, "INVALID_URI", INT2NUM(XML_ERR_INVALID_URI));
  rb_define_const(eXMLError, "URI_FRAGMENT", INT2NUM(XML_ERR_URI_FRAGMENT));
  rb_define_const(eXMLError, "XML_WAR_CATALOG_PI", INT2NUM(XML_WAR_CATALOG_PI));
  rb_define_const(eXMLError, "NO_DTD", INT2NUM(XML_ERR_NO_DTD));
  rb_define_const(eXMLError, "CONDSEC_INVALID_KEYWORD", INT2NUM(XML_ERR_CONDSEC_INVALID_KEYWORD));
  rb_define_const(eXMLError, "VERSION_MISSING", INT2NUM(XML_ERR_VERSION_MISSING));
  rb_define_const(eXMLError, "XML_WAR_UNKNOWN_VERSION", INT2NUM(XML_WAR_UNKNOWN_VERSION));
  rb_define_const(eXMLError, "XML_WAR_LANG_VALUE", INT2NUM(XML_WAR_LANG_VALUE));
  rb_define_const(eXMLError, "XML_WAR_NS_URI", INT2NUM(XML_WAR_NS_URI));
  rb_define_const(eXMLError, "XML_WAR_NS_URI_RELATIVE", INT2NUM(XML_WAR_NS_URI_RELATIVE));
  rb_define_const(eXMLError, "MISSING_ENCODING", INT2NUM(XML_ERR_MISSING_ENCODING));
#if LIBXML_VERSION >= 20620
  rb_define_const(eXMLError, "XML_WAR_SPACE_VALUE", INT2NUM(XML_WAR_SPACE_VALUE));
  rb_define_const(eXMLError, "NOT_STANDALONE", INT2NUM(XML_ERR_NOT_STANDALONE));
  rb_define_const(eXMLError, "ENTITY_PROCESSING", INT2NUM(XML_ERR_ENTITY_PROCESSING));
  rb_define_const(eXMLError, "NOTATION_PROCESSING", INT2NUM(XML_ERR_NOTATION_PROCESSING));
  rb_define_const(eXMLError, "WAR_NS_COLUMN", INT2NUM(XML_WAR_NS_COLUMN));
  rb_define_const(eXMLError, "WAR_ENTITY_REDEFINED", INT2NUM(XML_WAR_ENTITY_REDEFINED));
#endif
  rb_define_const(eXMLError, "NS_ERR_XML_NAMESPACE", INT2NUM(XML_NS_ERR_XML_NAMESPACE));
  rb_define_const(eXMLError, "NS_ERR_UNDEFINED_NAMESPACE", INT2NUM(XML_NS_ERR_UNDEFINED_NAMESPACE));
  rb_define_const(eXMLError, "NS_ERR_QNAME", INT2NUM(XML_NS_ERR_QNAME));
  rb_define_const(eXMLError, "NS_ERR_ATTRIBUTE_REDEFINED", INT2NUM(XML_NS_ERR_ATTRIBUTE_REDEFINED));
#if LIBXML_VERSION >= 20620
  rb_define_const(eXMLError, "NS_ERR_EMPTY", INT2NUM(XML_NS_ERR_EMPTY));
#endif
#if LIBXML_VERSION >= 20700
  rb_define_const(eXMLError, "NS_ERR_COLON", INT2NUM(XML_NS_ERR_COLON));
#endif
  rb_define_const(eXMLError, "DTD_ATTRIBUTE_DEFAULT", INT2NUM(XML_DTD_ATTRIBUTE_DEFAULT));
  rb_define_const(eXMLError, "DTD_ATTRIBUTE_REDEFINED", INT2NUM(XML_DTD_ATTRIBUTE_REDEFINED));
  rb_define_const(eXMLError, "DTD_ATTRIBUTE_VALUE", INT2NUM(XML_DTD_ATTRIBUTE_VALUE));
  rb_define_const(eXMLError, "DTD_CONTENT_ERROR", INT2NUM(XML_DTD_CONTENT_ERROR));
  rb_define_const(eXMLError, "DTD_CONTENT_MODEL", INT2NUM(XML_DTD_CONTENT_MODEL));
  rb_define_const(eXMLError, "DTD_CONTENT_NOT_DETERMINIST", INT2NUM(XML_DTD_CONTENT_NOT_DETERMINIST));
  rb_define_const(eXMLError, "DTD_DIFFERENT_PREFIX", INT2NUM(XML_DTD_DIFFERENT_PREFIX));
  rb_define_const(eXMLError, "DTD_ELEM_DEFAULT_NAMESPACE", INT2NUM(XML_DTD_ELEM_DEFAULT_NAMESPACE));
  rb_define_const(eXMLError, "DTD_ELEM_NAMESPACE", INT2NUM(XML_DTD_ELEM_NAMESPACE));
  rb_define_const(eXMLError, "DTD_ELEM_REDEFINED", INT2NUM(XML_DTD_ELEM_REDEFINED));
  rb_define_const(eXMLError, "DTD_EMPTY_NOTATION", INT2NUM(XML_DTD_EMPTY_NOTATION));
  rb_define_const(eXMLError, "DTD_ENTITY_TYPE", INT2NUM(XML_DTD_ENTITY_TYPE));
  rb_define_const(eXMLError, "DTD_ID_FIXED", INT2NUM(XML_DTD_ID_FIXED));
  rb_define_const(eXMLError, "DTD_ID_REDEFINED", INT2NUM(XML_DTD_ID_REDEFINED));
  rb_define_const(eXMLError, "DTD_ID_SUBSET", INT2NUM(XML_DTD_ID_SUBSET));
  rb_define_const(eXMLError, "DTD_INVALID_CHILD", INT2NUM(XML_DTD_INVALID_CHILD));
  rb_define_const(eXMLError, "DTD_INVALID_DEFAULT", INT2NUM(XML_DTD_INVALID_DEFAULT));
  rb_define_const(eXMLError, "DTD_LOAD_ERROR", INT2NUM(XML_DTD_LOAD_ERROR));
  rb_define_const(eXMLError, "DTD_MISSING_ATTRIBUTE", INT2NUM(XML_DTD_MISSING_ATTRIBUTE));
  rb_define_const(eXMLError, "DTD_MIXED_CORRUPT", INT2NUM(XML_DTD_MIXED_CORRUPT));
  rb_define_const(eXMLError, "DTD_MULTIPLE_ID", INT2NUM(XML_DTD_MULTIPLE_ID));
  rb_define_const(eXMLError, "DTD_NO_DOC", INT2NUM(XML_DTD_NO_DOC));
  rb_define_const(eXMLError, "DTD_NO_DTD", INT2NUM(XML_DTD_NO_DTD));
  rb_define_const(eXMLError, "DTD_NO_ELEM_NAME", INT2NUM(XML_DTD_NO_ELEM_NAME));
  rb_define_const(eXMLError, "DTD_NO_PREFIX", INT2NUM(XML_DTD_NO_PREFIX));
  rb_define_const(eXMLError, "DTD_NO_ROOT", INT2NUM(XML_DTD_NO_ROOT));
  rb_define_const(eXMLError, "DTD_NOTATION_REDEFINED", INT2NUM(XML_DTD_NOTATION_REDEFINED));
  rb_define_const(eXMLError, "DTD_NOTATION_VALUE", INT2NUM(XML_DTD_NOTATION_VALUE));
  rb_define_const(eXMLError, "DTD_NOT_EMPTY", INT2NUM(XML_DTD_NOT_EMPTY));
  rb_define_const(eXMLError, "DTD_NOT_PCDATA", INT2NUM(XML_DTD_NOT_PCDATA));
  rb_define_const(eXMLError, "DTD_NOT_STANDALONE", INT2NUM(XML_DTD_NOT_STANDALONE));
  rb_define_const(eXMLError, "DTD_ROOT_NAME", INT2NUM(XML_DTD_ROOT_NAME));
  rb_define_const(eXMLError, "DTD_STANDALONE_WHITE_SPACE", INT2NUM(XML_DTD_STANDALONE_WHITE_SPACE));
  rb_define_const(eXMLError, "DTD_UNKNOWN_ATTRIBUTE", INT2NUM(XML_DTD_UNKNOWN_ATTRIBUTE));
  rb_define_const(eXMLError, "DTD_UNKNOWN_ELEM", INT2NUM(XML_DTD_UNKNOWN_ELEM));
  rb_define_const(eXMLError, "DTD_UNKNOWN_ENTITY", INT2NUM(XML_DTD_UNKNOWN_ENTITY));
  rb_define_const(eXMLError, "DTD_UNKNOWN_ID", INT2NUM(XML_DTD_UNKNOWN_ID));
  rb_define_const(eXMLError, "DTD_UNKNOWN_NOTATION", INT2NUM(XML_DTD_UNKNOWN_NOTATION));
  rb_define_const(eXMLError, "DTD_STANDALONE_DEFAULTED", INT2NUM(XML_DTD_STANDALONE_DEFAULTED));
  rb_define_const(eXMLError, "DTD_XMLID_VALUE", INT2NUM(XML_DTD_XMLID_VALUE));
  rb_define_const(eXMLError, "DTD_XMLID_TYPE", INT2NUM(XML_DTD_XMLID_TYPE));
  rb_define_const(eXMLError, "HTML_STRUCURE_ERROR", INT2NUM(XML_HTML_STRUCURE_ERROR));
  rb_define_const(eXMLError, "HTML_UNKNOWN_TAG", INT2NUM(XML_HTML_UNKNOWN_TAG));
  rb_define_const(eXMLError, "RNGP_ANYNAME_ATTR_ANCESTOR", INT2NUM(XML_RNGP_ANYNAME_ATTR_ANCESTOR));
  rb_define_const(eXMLError, "RNGP_ATTR_CONFLICT", INT2NUM(XML_RNGP_ATTR_CONFLICT));
  rb_define_const(eXMLError, "RNGP_ATTRIBUTE_CHILDREN", INT2NUM(XML_RNGP_ATTRIBUTE_CHILDREN));
  rb_define_const(eXMLError, "RNGP_ATTRIBUTE_CONTENT", INT2NUM(XML_RNGP_ATTRIBUTE_CONTENT));
  rb_define_const(eXMLError, "RNGP_ATTRIBUTE_EMPTY", INT2NUM(XML_RNGP_ATTRIBUTE_EMPTY));
  rb_define_const(eXMLError, "RNGP_ATTRIBUTE_NOOP", INT2NUM(XML_RNGP_ATTRIBUTE_NOOP));
  rb_define_const(eXMLError, "RNGP_CHOICE_CONTENT", INT2NUM(XML_RNGP_CHOICE_CONTENT));
  rb_define_const(eXMLError, "RNGP_CHOICE_EMPTY", INT2NUM(XML_RNGP_CHOICE_EMPTY));
  rb_define_const(eXMLError, "RNGP_CREATE_FAILURE", INT2NUM(XML_RNGP_CREATE_FAILURE));
  rb_define_const(eXMLError, "RNGP_DATA_CONTENT", INT2NUM(XML_RNGP_DATA_CONTENT));
  rb_define_const(eXMLError, "RNGP_DEF_CHOICE_AND_INTERLEAVE", INT2NUM(XML_RNGP_DEF_CHOICE_AND_INTERLEAVE));
  rb_define_const(eXMLError, "RNGP_DEFINE_CREATE_FAILED", INT2NUM(XML_RNGP_DEFINE_CREATE_FAILED));
  rb_define_const(eXMLError, "RNGP_DEFINE_EMPTY", INT2NUM(XML_RNGP_DEFINE_EMPTY));
  rb_define_const(eXMLError, "RNGP_DEFINE_MISSING", INT2NUM(XML_RNGP_DEFINE_MISSING));
  rb_define_const(eXMLError, "RNGP_DEFINE_NAME_MISSING", INT2NUM(XML_RNGP_DEFINE_NAME_MISSING));
  rb_define_const(eXMLError, "RNGP_ELEM_CONTENT_EMPTY", INT2NUM(XML_RNGP_ELEM_CONTENT_EMPTY));
  rb_define_const(eXMLError, "RNGP_ELEM_CONTENT_ERROR", INT2NUM(XML_RNGP_ELEM_CONTENT_ERROR));
  rb_define_const(eXMLError, "RNGP_ELEMENT_EMPTY", INT2NUM(XML_RNGP_ELEMENT_EMPTY));
  rb_define_const(eXMLError, "RNGP_ELEMENT_CONTENT", INT2NUM(XML_RNGP_ELEMENT_CONTENT));
  rb_define_const(eXMLError, "RNGP_ELEMENT_NAME", INT2NUM(XML_RNGP_ELEMENT_NAME));
  rb_define_const(eXMLError, "RNGP_ELEMENT_NO_CONTENT", INT2NUM(XML_RNGP_ELEMENT_NO_CONTENT));
  rb_define_const(eXMLError, "RNGP_ELEM_TEXT_CONFLICT", INT2NUM(XML_RNGP_ELEM_TEXT_CONFLICT));
  rb_define_const(eXMLError, "RNGP_EMPTY", INT2NUM(XML_RNGP_EMPTY));
  rb_define_const(eXMLError, "RNGP_EMPTY_CONSTRUCT", INT2NUM(XML_RNGP_EMPTY_CONSTRUCT));
  rb_define_const(eXMLError, "RNGP_EMPTY_CONTENT", INT2NUM(XML_RNGP_EMPTY_CONTENT));
  rb_define_const(eXMLError, "RNGP_EMPTY_NOT_EMPTY", INT2NUM(XML_RNGP_EMPTY_NOT_EMPTY));
  rb_define_const(eXMLError, "RNGP_ERROR_TYPE_LIB", INT2NUM(XML_RNGP_ERROR_TYPE_LIB));
  rb_define_const(eXMLError, "RNGP_EXCEPT_EMPTY", INT2NUM(XML_RNGP_EXCEPT_EMPTY));
  rb_define_const(eXMLError, "RNGP_EXCEPT_MISSING", INT2NUM(XML_RNGP_EXCEPT_MISSING));
  rb_define_const(eXMLError, "RNGP_EXCEPT_MULTIPLE", INT2NUM(XML_RNGP_EXCEPT_MULTIPLE));
  rb_define_const(eXMLError, "RNGP_EXCEPT_NO_CONTENT", INT2NUM(XML_RNGP_EXCEPT_NO_CONTENT));
  rb_define_const(eXMLError, "RNGP_EXTERNALREF_EMTPY", INT2NUM(XML_RNGP_EXTERNALREF_EMTPY));
  rb_define_const(eXMLError, "RNGP_EXTERNAL_REF_FAILURE", INT2NUM(XML_RNGP_EXTERNAL_REF_FAILURE));
  rb_define_const(eXMLError, "RNGP_EXTERNALREF_RECURSE", INT2NUM(XML_RNGP_EXTERNALREF_RECURSE));
  rb_define_const(eXMLError, "RNGP_FORBIDDEN_ATTRIBUTE", INT2NUM(XML_RNGP_FORBIDDEN_ATTRIBUTE));
  rb_define_const(eXMLError, "RNGP_FOREIGN_ELEMENT", INT2NUM(XML_RNGP_FOREIGN_ELEMENT));
  rb_define_const(eXMLError, "RNGP_GRAMMAR_CONTENT", INT2NUM(XML_RNGP_GRAMMAR_CONTENT));
  rb_define_const(eXMLError, "RNGP_GRAMMAR_EMPTY", INT2NUM(XML_RNGP_GRAMMAR_EMPTY));
  rb_define_const(eXMLError, "RNGP_GRAMMAR_MISSING", INT2NUM(XML_RNGP_GRAMMAR_MISSING));
  rb_define_const(eXMLError, "RNGP_GRAMMAR_NO_START", INT2NUM(XML_RNGP_GRAMMAR_NO_START));
  rb_define_const(eXMLError, "RNGP_GROUP_ATTR_CONFLICT", INT2NUM(XML_RNGP_GROUP_ATTR_CONFLICT));
  rb_define_const(eXMLError, "RNGP_HREF_ERROR", INT2NUM(XML_RNGP_HREF_ERROR));
  rb_define_const(eXMLError, "RNGP_INCLUDE_EMPTY", INT2NUM(XML_RNGP_INCLUDE_EMPTY));
  rb_define_const(eXMLError, "RNGP_INCLUDE_FAILURE", INT2NUM(XML_RNGP_INCLUDE_FAILURE));
  rb_define_const(eXMLError, "RNGP_INCLUDE_RECURSE", INT2NUM(XML_RNGP_INCLUDE_RECURSE));
  rb_define_const(eXMLError, "RNGP_INTERLEAVE_ADD", INT2NUM(XML_RNGP_INTERLEAVE_ADD));
  rb_define_const(eXMLError, "RNGP_INTERLEAVE_CREATE_FAILED", INT2NUM(XML_RNGP_INTERLEAVE_CREATE_FAILED));
  rb_define_const(eXMLError, "RNGP_INTERLEAVE_EMPTY", INT2NUM(XML_RNGP_INTERLEAVE_EMPTY));
  rb_define_const(eXMLError, "RNGP_INTERLEAVE_NO_CONTENT", INT2NUM(XML_RNGP_INTERLEAVE_NO_CONTENT));
  rb_define_const(eXMLError, "RNGP_INVALID_DEFINE_NAME", INT2NUM(XML_RNGP_INVALID_DEFINE_NAME));
  rb_define_const(eXMLError, "RNGP_INVALID_URI", INT2NUM(XML_RNGP_INVALID_URI));
  rb_define_const(eXMLError, "RNGP_INVALID_VALUE", INT2NUM(XML_RNGP_INVALID_VALUE));
  rb_define_const(eXMLError, "RNGP_MISSING_HREF", INT2NUM(XML_RNGP_MISSING_HREF));
  rb_define_const(eXMLError, "RNGP_NAME_MISSING", INT2NUM(XML_RNGP_NAME_MISSING));
  rb_define_const(eXMLError, "RNGP_NEED_COMBINE", INT2NUM(XML_RNGP_NEED_COMBINE));
  rb_define_const(eXMLError, "RNGP_NOTALLOWED_NOT_EMPTY", INT2NUM(XML_RNGP_NOTALLOWED_NOT_EMPTY));
  rb_define_const(eXMLError, "RNGP_NSNAME_ATTR_ANCESTOR", INT2NUM(XML_RNGP_NSNAME_ATTR_ANCESTOR));
  rb_define_const(eXMLError, "RNGP_NSNAME_NO_NS", INT2NUM(XML_RNGP_NSNAME_NO_NS));
  rb_define_const(eXMLError, "RNGP_PARAM_FORBIDDEN", INT2NUM(XML_RNGP_PARAM_FORBIDDEN));
  rb_define_const(eXMLError, "RNGP_PARAM_NAME_MISSING", INT2NUM(XML_RNGP_PARAM_NAME_MISSING));
  rb_define_const(eXMLError, "RNGP_PARENTREF_CREATE_FAILED", INT2NUM(XML_RNGP_PARENTREF_CREATE_FAILED));
  rb_define_const(eXMLError, "RNGP_PARENTREF_NAME_INVALID", INT2NUM(XML_RNGP_PARENTREF_NAME_INVALID));
  rb_define_const(eXMLError, "RNGP_PARENTREF_NO_NAME", INT2NUM(XML_RNGP_PARENTREF_NO_NAME));
  rb_define_const(eXMLError, "RNGP_PARENTREF_NO_PARENT", INT2NUM(XML_RNGP_PARENTREF_NO_PARENT));
  rb_define_const(eXMLError, "RNGP_PARENTREF_NOT_EMPTY", INT2NUM(XML_RNGP_PARENTREF_NOT_EMPTY));
  rb_define_const(eXMLError, "RNGP_PARSE_ERROR", INT2NUM(XML_RNGP_PARSE_ERROR));
  rb_define_const(eXMLError, "RNGP_PAT_ANYNAME_EXCEPT_ANYNAME", INT2NUM(XML_RNGP_PAT_ANYNAME_EXCEPT_ANYNAME));
  rb_define_const(eXMLError, "RNGP_PAT_ATTR_ATTR", INT2NUM(XML_RNGP_PAT_ATTR_ATTR));
  rb_define_const(eXMLError, "RNGP_PAT_ATTR_ELEM", INT2NUM(XML_RNGP_PAT_ATTR_ELEM));
  rb_define_const(eXMLError, "RNGP_PAT_DATA_EXCEPT_ATTR", INT2NUM(XML_RNGP_PAT_DATA_EXCEPT_ATTR));
  rb_define_const(eXMLError, "RNGP_PAT_DATA_EXCEPT_ELEM", INT2NUM(XML_RNGP_PAT_DATA_EXCEPT_ELEM));
  rb_define_const(eXMLError, "RNGP_PAT_DATA_EXCEPT_EMPTY", INT2NUM(XML_RNGP_PAT_DATA_EXCEPT_EMPTY));
  rb_define_const(eXMLError, "RNGP_PAT_DATA_EXCEPT_GROUP", INT2NUM(XML_RNGP_PAT_DATA_EXCEPT_GROUP));
  rb_define_const(eXMLError, "RNGP_PAT_DATA_EXCEPT_INTERLEAVE", INT2NUM(XML_RNGP_PAT_DATA_EXCEPT_INTERLEAVE));
  rb_define_const(eXMLError, "RNGP_PAT_DATA_EXCEPT_LIST", INT2NUM(XML_RNGP_PAT_DATA_EXCEPT_LIST));
  rb_define_const(eXMLError, "RNGP_PAT_DATA_EXCEPT_ONEMORE", INT2NUM(XML_RNGP_PAT_DATA_EXCEPT_ONEMORE));
  rb_define_const(eXMLError, "RNGP_PAT_DATA_EXCEPT_REF", INT2NUM(XML_RNGP_PAT_DATA_EXCEPT_REF));
  rb_define_const(eXMLError, "RNGP_PAT_DATA_EXCEPT_TEXT", INT2NUM(XML_RNGP_PAT_DATA_EXCEPT_TEXT));
  rb_define_const(eXMLError, "RNGP_PAT_LIST_ATTR", INT2NUM(XML_RNGP_PAT_LIST_ATTR));
  rb_define_const(eXMLError, "RNGP_PAT_LIST_ELEM", INT2NUM(XML_RNGP_PAT_LIST_ELEM));
  rb_define_const(eXMLError, "RNGP_PAT_LIST_INTERLEAVE", INT2NUM(XML_RNGP_PAT_LIST_INTERLEAVE));
  rb_define_const(eXMLError, "RNGP_PAT_LIST_LIST", INT2NUM(XML_RNGP_PAT_LIST_LIST));
  rb_define_const(eXMLError, "RNGP_PAT_LIST_REF", INT2NUM(XML_RNGP_PAT_LIST_REF));
  rb_define_const(eXMLError, "RNGP_PAT_LIST_TEXT", INT2NUM(XML_RNGP_PAT_LIST_TEXT));
  rb_define_const(eXMLError, "RNGP_PAT_NSNAME_EXCEPT_ANYNAME", INT2NUM(XML_RNGP_PAT_NSNAME_EXCEPT_ANYNAME));
  rb_define_const(eXMLError, "RNGP_PAT_NSNAME_EXCEPT_NSNAME", INT2NUM(XML_RNGP_PAT_NSNAME_EXCEPT_NSNAME));
  rb_define_const(eXMLError, "RNGP_PAT_ONEMORE_GROUP_ATTR", INT2NUM(XML_RNGP_PAT_ONEMORE_GROUP_ATTR));
  rb_define_const(eXMLError, "RNGP_PAT_ONEMORE_INTERLEAVE_ATTR", INT2NUM(XML_RNGP_PAT_ONEMORE_INTERLEAVE_ATTR));
  rb_define_const(eXMLError, "RNGP_PAT_START_ATTR", INT2NUM(XML_RNGP_PAT_START_ATTR));
  rb_define_const(eXMLError, "RNGP_PAT_START_DATA", INT2NUM(XML_RNGP_PAT_START_DATA));
  rb_define_const(eXMLError, "RNGP_PAT_START_EMPTY", INT2NUM(XML_RNGP_PAT_START_EMPTY));
  rb_define_const(eXMLError, "RNGP_PAT_START_GROUP", INT2NUM(XML_RNGP_PAT_START_GROUP));
  rb_define_const(eXMLError, "RNGP_PAT_START_INTERLEAVE", INT2NUM(XML_RNGP_PAT_START_INTERLEAVE));
  rb_define_const(eXMLError, "RNGP_PAT_START_LIST", INT2NUM(XML_RNGP_PAT_START_LIST));
  rb_define_const(eXMLError, "RNGP_PAT_START_ONEMORE", INT2NUM(XML_RNGP_PAT_START_ONEMORE));
  rb_define_const(eXMLError, "RNGP_PAT_START_TEXT", INT2NUM(XML_RNGP_PAT_START_TEXT));
  rb_define_const(eXMLError, "RNGP_PAT_START_VALUE", INT2NUM(XML_RNGP_PAT_START_VALUE));
  rb_define_const(eXMLError, "RNGP_PREFIX_UNDEFINED", INT2NUM(XML_RNGP_PREFIX_UNDEFINED));
  rb_define_const(eXMLError, "RNGP_REF_CREATE_FAILED", INT2NUM(XML_RNGP_REF_CREATE_FAILED));
  rb_define_const(eXMLError, "RNGP_REF_CYCLE", INT2NUM(XML_RNGP_REF_CYCLE));
  rb_define_const(eXMLError, "RNGP_REF_NAME_INVALID", INT2NUM(XML_RNGP_REF_NAME_INVALID));
  rb_define_const(eXMLError, "RNGP_REF_NO_DEF", INT2NUM(XML_RNGP_REF_NO_DEF));
  rb_define_const(eXMLError, "RNGP_REF_NO_NAME", INT2NUM(XML_RNGP_REF_NO_NAME));
  rb_define_const(eXMLError, "RNGP_REF_NOT_EMPTY", INT2NUM(XML_RNGP_REF_NOT_EMPTY));
  rb_define_const(eXMLError, "RNGP_START_CHOICE_AND_INTERLEAVE", INT2NUM(XML_RNGP_START_CHOICE_AND_INTERLEAVE));
  rb_define_const(eXMLError, "RNGP_START_CONTENT", INT2NUM(XML_RNGP_START_CONTENT));
  rb_define_const(eXMLError, "RNGP_START_EMPTY", INT2NUM(XML_RNGP_START_EMPTY));
  rb_define_const(eXMLError, "RNGP_START_MISSING", INT2NUM(XML_RNGP_START_MISSING));
  rb_define_const(eXMLError, "RNGP_TEXT_EXPECTED", INT2NUM(XML_RNGP_TEXT_EXPECTED));
  rb_define_const(eXMLError, "RNGP_TEXT_HAS_CHILD", INT2NUM(XML_RNGP_TEXT_HAS_CHILD));
  rb_define_const(eXMLError, "RNGP_TYPE_MISSING", INT2NUM(XML_RNGP_TYPE_MISSING));
  rb_define_const(eXMLError, "RNGP_TYPE_NOT_FOUND", INT2NUM(XML_RNGP_TYPE_NOT_FOUND));
  rb_define_const(eXMLError, "RNGP_TYPE_VALUE", INT2NUM(XML_RNGP_TYPE_VALUE));
  rb_define_const(eXMLError, "RNGP_UNKNOWN_ATTRIBUTE", INT2NUM(XML_RNGP_UNKNOWN_ATTRIBUTE));
  rb_define_const(eXMLError, "RNGP_UNKNOWN_COMBINE", INT2NUM(XML_RNGP_UNKNOWN_COMBINE));
  rb_define_const(eXMLError, "RNGP_UNKNOWN_CONSTRUCT", INT2NUM(XML_RNGP_UNKNOWN_CONSTRUCT));
  rb_define_const(eXMLError, "RNGP_UNKNOWN_TYPE_LIB", INT2NUM(XML_RNGP_UNKNOWN_TYPE_LIB));
  rb_define_const(eXMLError, "RNGP_URI_FRAGMENT", INT2NUM(XML_RNGP_URI_FRAGMENT));
  rb_define_const(eXMLError, "RNGP_URI_NOT_ABSOLUTE", INT2NUM(XML_RNGP_URI_NOT_ABSOLUTE));
  rb_define_const(eXMLError, "RNGP_VALUE_EMPTY", INT2NUM(XML_RNGP_VALUE_EMPTY));
  rb_define_const(eXMLError, "RNGP_VALUE_NO_CONTENT", INT2NUM(XML_RNGP_VALUE_NO_CONTENT));
  rb_define_const(eXMLError, "RNGP_XMLNS_NAME", INT2NUM(XML_RNGP_XMLNS_NAME));
  rb_define_const(eXMLError, "RNGP_XML_NS", INT2NUM(XML_RNGP_XML_NS));
  rb_define_const(eXMLError, "XPATH_EXPRESSION_OK", INT2NUM(XML_XPATH_EXPRESSION_OK));
  rb_define_const(eXMLError, "XPATH_NUMBER_ERROR", INT2NUM(XML_XPATH_NUMBER_ERROR));
  rb_define_const(eXMLError, "XPATH_UNFINISHED_LITERAL_ERROR", INT2NUM(XML_XPATH_UNFINISHED_LITERAL_ERROR));
  rb_define_const(eXMLError, "XPATH_START_LITERAL_ERROR", INT2NUM(XML_XPATH_START_LITERAL_ERROR));
  rb_define_const(eXMLError, "XPATH_VARIABLE_REF_ERROR", INT2NUM(XML_XPATH_VARIABLE_REF_ERROR));
  rb_define_const(eXMLError, "XPATH_UNDEF_VARIABLE_ERROR", INT2NUM(XML_XPATH_UNDEF_VARIABLE_ERROR));
  rb_define_const(eXMLError, "XPATH_INVALID_PREDICATE_ERROR", INT2NUM(XML_XPATH_INVALID_PREDICATE_ERROR));
  rb_define_const(eXMLError, "XPATH_EXPR_ERROR", INT2NUM(XML_XPATH_EXPR_ERROR));
  rb_define_const(eXMLError, "XPATH_UNCLOSED_ERROR", INT2NUM(XML_XPATH_UNCLOSED_ERROR));
  rb_define_const(eXMLError, "XPATH_UNKNOWN_FUNC_ERROR", INT2NUM(XML_XPATH_UNKNOWN_FUNC_ERROR));
  rb_define_const(eXMLError, "XPATH_INVALID_OPERAND", INT2NUM(XML_XPATH_INVALID_OPERAND));
  rb_define_const(eXMLError, "XPATH_INVALID_TYPE", INT2NUM(XML_XPATH_INVALID_TYPE));
  rb_define_const(eXMLError, "XPATH_INVALID_ARITY", INT2NUM(XML_XPATH_INVALID_ARITY));
  rb_define_const(eXMLError, "XPATH_INVALID_CTXT_SIZE", INT2NUM(XML_XPATH_INVALID_CTXT_SIZE));
  rb_define_const(eXMLError, "XPATH_INVALID_CTXT_POSITION", INT2NUM(XML_XPATH_INVALID_CTXT_POSITION));
  rb_define_const(eXMLError, "XPATH_MEMORY_ERROR", INT2NUM(XML_XPATH_MEMORY_ERROR));
  rb_define_const(eXMLError, "XPTR_SYNTAX_ERROR", INT2NUM(XML_XPTR_SYNTAX_ERROR));
  rb_define_const(eXMLError, "XPTR_RESOURCE_ERROR", INT2NUM(XML_XPTR_RESOURCE_ERROR));
  rb_define_const(eXMLError, "XPTR_SUB_RESOURCE_ERROR", INT2NUM(XML_XPTR_SUB_RESOURCE_ERROR));
  rb_define_const(eXMLError, "XPATH_UNDEF_PREFIX_ERROR", INT2NUM(XML_XPATH_UNDEF_PREFIX_ERROR));
  rb_define_const(eXMLError, "XPATH_ENCODING_ERROR", INT2NUM(XML_XPATH_ENCODING_ERROR));
  rb_define_const(eXMLError, "XPATH_INVALID_CHAR_ERROR", INT2NUM(XML_XPATH_INVALID_CHAR_ERROR));
  rb_define_const(eXMLError, "TREE_INVALID_HEX", INT2NUM(XML_TREE_INVALID_HEX));
  rb_define_const(eXMLError, "TREE_INVALID_DEC", INT2NUM(XML_TREE_INVALID_DEC));
  rb_define_const(eXMLError, "TREE_UNTERMINATED_ENTITY", INT2NUM(XML_TREE_UNTERMINATED_ENTITY));
#if LIBXML_VERSION >= 20632
  rb_define_const(eXMLError, "TREE_NOT_UTF8", INT2NUM(XML_TREE_NOT_UTF8));
#endif
  rb_define_const(eXMLError, "SAVE_NOT_UTF8", INT2NUM(XML_SAVE_NOT_UTF8));
  rb_define_const(eXMLError, "SAVE_CHAR_INVALID", INT2NUM(XML_SAVE_CHAR_INVALID));
  rb_define_const(eXMLError, "SAVE_NO_DOCTYPE", INT2NUM(XML_SAVE_NO_DOCTYPE));
  rb_define_const(eXMLError, "SAVE_UNKNOWN_ENCODING", INT2NUM(XML_SAVE_UNKNOWN_ENCODING));
  rb_define_const(eXMLError, "REGEXP_COMPILE_ERROR", INT2NUM(XML_REGEXP_COMPILE_ERROR));
  rb_define_const(eXMLError, "IO_UNKNOWN", INT2NUM(XML_IO_UNKNOWN));
  rb_define_const(eXMLError, "IO_EACCES", INT2NUM(XML_IO_EACCES));
  rb_define_const(eXMLError, "IO_EAGAIN", INT2NUM(XML_IO_EAGAIN));
  rb_define_const(eXMLError, "IO_EBADF", INT2NUM(XML_IO_EBADF));
  rb_define_const(eXMLError, "IO_EBADMSG", INT2NUM(XML_IO_EBADMSG));
  rb_define_const(eXMLError, "IO_EBUSY", INT2NUM(XML_IO_EBUSY));
  rb_define_const(eXMLError, "IO_ECANCELED", INT2NUM(XML_IO_ECANCELED));
  rb_define_const(eXMLError, "IO_ECHILD", INT2NUM(XML_IO_ECHILD));
  rb_define_const(eXMLError, "IO_EDEADLK", INT2NUM(XML_IO_EDEADLK));
  rb_define_const(eXMLError, "IO_EDOM", INT2NUM(XML_IO_EDOM));
  rb_define_const(eXMLError, "IO_EEXIST", INT2NUM(XML_IO_EEXIST));
  rb_define_const(eXMLError, "IO_EFAULT", INT2NUM(XML_IO_EFAULT));
  rb_define_const(eXMLError, "IO_EFBIG", INT2NUM(XML_IO_EFBIG));
  rb_define_const(eXMLError, "IO_EINPROGRESS", INT2NUM(XML_IO_EINPROGRESS));
  rb_define_const(eXMLError, "IO_EINTR", INT2NUM(XML_IO_EINTR));
  rb_define_const(eXMLError, "IO_EINVAL", INT2NUM(XML_IO_EINVAL));
  rb_define_const(eXMLError, "IO_EIO", INT2NUM(XML_IO_EIO));
  rb_define_const(eXMLError, "IO_EISDIR", INT2NUM(XML_IO_EISDIR));
  rb_define_const(eXMLError, "IO_EMFILE", INT2NUM(XML_IO_EMFILE));
  rb_define_const(eXMLError, "IO_EMLINK", INT2NUM(XML_IO_EMLINK));
  rb_define_const(eXMLError, "IO_EMSGSIZE", INT2NUM(XML_IO_EMSGSIZE));
  rb_define_const(eXMLError, "IO_ENAMETOOLONG", INT2NUM(XML_IO_ENAMETOOLONG));
  rb_define_const(eXMLError, "IO_ENFILE", INT2NUM(XML_IO_ENFILE));
  rb_define_const(eXMLError, "IO_ENODEV", INT2NUM(XML_IO_ENODEV));
  rb_define_const(eXMLError, "IO_ENOENT", INT2NUM(XML_IO_ENOENT));
  rb_define_const(eXMLError, "IO_ENOEXEC", INT2NUM(XML_IO_ENOEXEC));
  rb_define_const(eXMLError, "IO_ENOLCK", INT2NUM(XML_IO_ENOLCK));
  rb_define_const(eXMLError, "IO_ENOMEM", INT2NUM(XML_IO_ENOMEM));
  rb_define_const(eXMLError, "IO_ENOSPC", INT2NUM(XML_IO_ENOSPC));
  rb_define_const(eXMLError, "IO_ENOSYS", INT2NUM(XML_IO_ENOSYS));
  rb_define_const(eXMLError, "IO_ENOTDIR", INT2NUM(XML_IO_ENOTDIR));
  rb_define_const(eXMLError, "IO_ENOTEMPTY", INT2NUM(XML_IO_ENOTEMPTY));
  rb_define_const(eXMLError, "IO_ENOTSUP", INT2NUM(XML_IO_ENOTSUP));
  rb_define_const(eXMLError, "IO_ENOTTY", INT2NUM(XML_IO_ENOTTY));
  rb_define_const(eXMLError, "IO_ENXIO", INT2NUM(XML_IO_ENXIO));
  rb_define_const(eXMLError, "IO_EPERM", INT2NUM(XML_IO_EPERM));
  rb_define_const(eXMLError, "IO_EPIPE", INT2NUM(XML_IO_EPIPE));
  rb_define_const(eXMLError, "IO_ERANGE", INT2NUM(XML_IO_ERANGE));
  rb_define_const(eXMLError, "IO_EROFS", INT2NUM(XML_IO_EROFS));
  rb_define_const(eXMLError, "IO_ESPIPE", INT2NUM(XML_IO_ESPIPE));
  rb_define_const(eXMLError, "IO_ESRCH", INT2NUM(XML_IO_ESRCH));
  rb_define_const(eXMLError, "IO_ETIMEDOUT", INT2NUM(XML_IO_ETIMEDOUT));
  rb_define_const(eXMLError, "IO_EXDEV", INT2NUM(XML_IO_EXDEV));
  rb_define_const(eXMLError, "IO_NETWORK_ATTEMPT", INT2NUM(XML_IO_NETWORK_ATTEMPT));
  rb_define_const(eXMLError, "IO_ENCODER", INT2NUM(XML_IO_ENCODER));
  rb_define_const(eXMLError, "IO_FLUSH", INT2NUM(XML_IO_FLUSH));
  rb_define_const(eXMLError, "IO_WRITE", INT2NUM(XML_IO_WRITE));
  rb_define_const(eXMLError, "IO_NO_INPUT", INT2NUM(XML_IO_NO_INPUT));
  rb_define_const(eXMLError, "IO_BUFFER_FULL", INT2NUM(XML_IO_BUFFER_FULL));
  rb_define_const(eXMLError, "IO_LOAD_ERROR", INT2NUM(XML_IO_LOAD_ERROR));
  rb_define_const(eXMLError, "IO_ENOTSOCK", INT2NUM(XML_IO_ENOTSOCK));
  rb_define_const(eXMLError, "IO_EISCONN", INT2NUM(XML_IO_EISCONN));
  rb_define_const(eXMLError, "IO_ECONNREFUSED", INT2NUM(XML_IO_ECONNREFUSED));
  rb_define_const(eXMLError, "IO_ENETUNREACH", INT2NUM(XML_IO_ENETUNREACH));
  rb_define_const(eXMLError, "IO_EADDRINUSE", INT2NUM(XML_IO_EADDRINUSE));
  rb_define_const(eXMLError, "IO_EALREADY", INT2NUM(XML_IO_EALREADY));
  rb_define_const(eXMLError, "IO_EAFNOSUPPORT", INT2NUM(XML_IO_EAFNOSUPPORT));
  rb_define_const(eXMLError, "XINCLUDE_RECURSION", INT2NUM(XML_XINCLUDE_RECURSION));
  rb_define_const(eXMLError, "XINCLUDE_PARSE_VALUE", INT2NUM(XML_XINCLUDE_PARSE_VALUE));
  rb_define_const(eXMLError, "XINCLUDE_ENTITY_DEF_MISMATCH", INT2NUM(XML_XINCLUDE_ENTITY_DEF_MISMATCH));
  rb_define_const(eXMLError, "XINCLUDE_NO_HREF", INT2NUM(XML_XINCLUDE_NO_HREF));
  rb_define_const(eXMLError, "XINCLUDE_NO_FALLBACK", INT2NUM(XML_XINCLUDE_NO_FALLBACK));
  rb_define_const(eXMLError, "XINCLUDE_HREF_URI", INT2NUM(XML_XINCLUDE_HREF_URI));
  rb_define_const(eXMLError, "XINCLUDE_TEXT_FRAGMENT", INT2NUM(XML_XINCLUDE_TEXT_FRAGMENT));
  rb_define_const(eXMLError, "XINCLUDE_TEXT_DOCUMENT", INT2NUM(XML_XINCLUDE_TEXT_DOCUMENT));
  rb_define_const(eXMLError, "XINCLUDE_INVALID_CHAR", INT2NUM(XML_XINCLUDE_INVALID_CHAR));
  rb_define_const(eXMLError, "XINCLUDE_BUILD_FAILED", INT2NUM(XML_XINCLUDE_BUILD_FAILED));
  rb_define_const(eXMLError, "XINCLUDE_UNKNOWN_ENCODING", INT2NUM(XML_XINCLUDE_UNKNOWN_ENCODING));
  rb_define_const(eXMLError, "XINCLUDE_MULTIPLE_ROOT", INT2NUM(XML_XINCLUDE_MULTIPLE_ROOT));
  rb_define_const(eXMLError, "XINCLUDE_XPTR_FAILED", INT2NUM(XML_XINCLUDE_XPTR_FAILED));
  rb_define_const(eXMLError, "XINCLUDE_XPTR_RESULT", INT2NUM(XML_XINCLUDE_XPTR_RESULT));
  rb_define_const(eXMLError, "XINCLUDE_INCLUDE_IN_INCLUDE", INT2NUM(XML_XINCLUDE_INCLUDE_IN_INCLUDE));
  rb_define_const(eXMLError, "XINCLUDE_FALLBACKS_IN_INCLUDE", INT2NUM(XML_XINCLUDE_FALLBACKS_IN_INCLUDE));
  rb_define_const(eXMLError, "XINCLUDE_FALLBACK_NOT_IN_INCLUDE", INT2NUM(XML_XINCLUDE_FALLBACK_NOT_IN_INCLUDE));
  rb_define_const(eXMLError, "XINCLUDE_DEPRECATED_NS", INT2NUM(XML_XINCLUDE_DEPRECATED_NS));
  rb_define_const(eXMLError, "XINCLUDE_FRAGMENT_ID", INT2NUM(XML_XINCLUDE_FRAGMENT_ID));
  rb_define_const(eXMLError, "CATALOG_MISSING_ATTR", INT2NUM(XML_CATALOG_MISSING_ATTR));
  rb_define_const(eXMLError, "CATALOG_ENTRY_BROKEN", INT2NUM(XML_CATALOG_ENTRY_BROKEN));
  rb_define_const(eXMLError, "CATALOG_PREFER_VALUE", INT2NUM(XML_CATALOG_PREFER_VALUE));
  rb_define_const(eXMLError, "CATALOG_NOT_CATALOG", INT2NUM(XML_CATALOG_NOT_CATALOG));
  rb_define_const(eXMLError, "CATALOG_RECURSION", INT2NUM(XML_CATALOG_RECURSION));
  rb_define_const(eXMLError, "SCHEMAP_PREFIX_UNDEFINED", INT2NUM(XML_SCHEMAP_PREFIX_UNDEFINED));
  rb_define_const(eXMLError, "SCHEMAP_ATTRFORMDEFAULT_VALUE", INT2NUM(XML_SCHEMAP_ATTRFORMDEFAULT_VALUE));
  rb_define_const(eXMLError, "SCHEMAP_ATTRGRP_NONAME_NOREF", INT2NUM(XML_SCHEMAP_ATTRGRP_NONAME_NOREF));
  rb_define_const(eXMLError, "SCHEMAP_ATTR_NONAME_NOREF", INT2NUM(XML_SCHEMAP_ATTR_NONAME_NOREF));
  rb_define_const(eXMLError, "SCHEMAP_COMPLEXTYPE_NONAME_NOREF", INT2NUM(XML_SCHEMAP_COMPLEXTYPE_NONAME_NOREF));
  rb_define_const(eXMLError, "SCHEMAP_ELEMFORMDEFAULT_VALUE", INT2NUM(XML_SCHEMAP_ELEMFORMDEFAULT_VALUE));
  rb_define_const(eXMLError, "SCHEMAP_ELEM_NONAME_NOREF", INT2NUM(XML_SCHEMAP_ELEM_NONAME_NOREF));
  rb_define_const(eXMLError, "SCHEMAP_EXTENSION_NO_BASE", INT2NUM(XML_SCHEMAP_EXTENSION_NO_BASE));
  rb_define_const(eXMLError, "SCHEMAP_FACET_NO_VALUE", INT2NUM(XML_SCHEMAP_FACET_NO_VALUE));
  rb_define_const(eXMLError, "SCHEMAP_FAILED_BUILD_IMPORT", INT2NUM(XML_SCHEMAP_FAILED_BUILD_IMPORT));
  rb_define_const(eXMLError, "SCHEMAP_GROUP_NONAME_NOREF", INT2NUM(XML_SCHEMAP_GROUP_NONAME_NOREF));
  rb_define_const(eXMLError, "SCHEMAP_IMPORT_NAMESPACE_NOT_URI", INT2NUM(XML_SCHEMAP_IMPORT_NAMESPACE_NOT_URI));
  rb_define_const(eXMLError, "SCHEMAP_IMPORT_REDEFINE_NSNAME", INT2NUM(XML_SCHEMAP_IMPORT_REDEFINE_NSNAME));
  rb_define_const(eXMLError, "SCHEMAP_IMPORT_SCHEMA_NOT_URI", INT2NUM(XML_SCHEMAP_IMPORT_SCHEMA_NOT_URI));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_BOOLEAN", INT2NUM(XML_SCHEMAP_INVALID_BOOLEAN));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_ENUM", INT2NUM(XML_SCHEMAP_INVALID_ENUM));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_FACET", INT2NUM(XML_SCHEMAP_INVALID_FACET));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_FACET_VALUE", INT2NUM(XML_SCHEMAP_INVALID_FACET_VALUE));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_MAXOCCURS", INT2NUM(XML_SCHEMAP_INVALID_MAXOCCURS));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_MINOCCURS", INT2NUM(XML_SCHEMAP_INVALID_MINOCCURS));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_REF_AND_SUBTYPE", INT2NUM(XML_SCHEMAP_INVALID_REF_AND_SUBTYPE));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_WHITE_SPACE", INT2NUM(XML_SCHEMAP_INVALID_WHITE_SPACE));
  rb_define_const(eXMLError, "SCHEMAP_NOATTR_NOREF", INT2NUM(XML_SCHEMAP_NOATTR_NOREF));
  rb_define_const(eXMLError, "SCHEMAP_NOTATION_NO_NAME", INT2NUM(XML_SCHEMAP_NOTATION_NO_NAME));
  rb_define_const(eXMLError, "SCHEMAP_NOTYPE_NOREF", INT2NUM(XML_SCHEMAP_NOTYPE_NOREF));
  rb_define_const(eXMLError, "SCHEMAP_REF_AND_SUBTYPE", INT2NUM(XML_SCHEMAP_REF_AND_SUBTYPE));
  rb_define_const(eXMLError, "SCHEMAP_RESTRICTION_NONAME_NOREF", INT2NUM(XML_SCHEMAP_RESTRICTION_NONAME_NOREF));
  rb_define_const(eXMLError, "SCHEMAP_SIMPLETYPE_NONAME", INT2NUM(XML_SCHEMAP_SIMPLETYPE_NONAME));
  rb_define_const(eXMLError, "SCHEMAP_TYPE_AND_SUBTYPE", INT2NUM(XML_SCHEMAP_TYPE_AND_SUBTYPE));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_ALL_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_ALL_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_ANYATTRIBUTE_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_ANYATTRIBUTE_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_ATTR_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_ATTR_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_ATTRGRP_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_ATTRGRP_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_ATTRIBUTE_GROUP", INT2NUM(XML_SCHEMAP_UNKNOWN_ATTRIBUTE_GROUP));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_BASE_TYPE", INT2NUM(XML_SCHEMAP_UNKNOWN_BASE_TYPE));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_CHOICE_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_CHOICE_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_COMPLEXCONTENT_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_COMPLEXCONTENT_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_COMPLEXTYPE_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_COMPLEXTYPE_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_ELEM_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_ELEM_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_EXTENSION_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_EXTENSION_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_FACET_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_FACET_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_FACET_TYPE", INT2NUM(XML_SCHEMAP_UNKNOWN_FACET_TYPE));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_GROUP_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_GROUP_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_IMPORT_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_IMPORT_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_LIST_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_LIST_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_NOTATION_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_NOTATION_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_PROCESSCONTENT_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_PROCESSCONTENT_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_REF", INT2NUM(XML_SCHEMAP_UNKNOWN_REF));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_RESTRICTION_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_RESTRICTION_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_SCHEMAS_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_SCHEMAS_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_SEQUENCE_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_SEQUENCE_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_SIMPLECONTENT_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_SIMPLECONTENT_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_SIMPLETYPE_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_SIMPLETYPE_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_TYPE", INT2NUM(XML_SCHEMAP_UNKNOWN_TYPE));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_UNION_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_UNION_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_ELEM_DEFAULT_FIXED", INT2NUM(XML_SCHEMAP_ELEM_DEFAULT_FIXED));
  rb_define_const(eXMLError, "SCHEMAP_REGEXP_INVALID", INT2NUM(XML_SCHEMAP_REGEXP_INVALID));
  rb_define_const(eXMLError, "SCHEMAP_FAILED_LOAD", INT2NUM(XML_SCHEMAP_FAILED_LOAD));
  rb_define_const(eXMLError, "SCHEMAP_NOTHING_TO_PARSE", INT2NUM(XML_SCHEMAP_NOTHING_TO_PARSE));
  rb_define_const(eXMLError, "SCHEMAP_NOROOT", INT2NUM(XML_SCHEMAP_NOROOT));
  rb_define_const(eXMLError, "SCHEMAP_REDEFINED_GROUP", INT2NUM(XML_SCHEMAP_REDEFINED_GROUP));
  rb_define_const(eXMLError, "SCHEMAP_REDEFINED_TYPE", INT2NUM(XML_SCHEMAP_REDEFINED_TYPE));
  rb_define_const(eXMLError, "SCHEMAP_REDEFINED_ELEMENT", INT2NUM(XML_SCHEMAP_REDEFINED_ELEMENT));
  rb_define_const(eXMLError, "SCHEMAP_REDEFINED_ATTRGROUP", INT2NUM(XML_SCHEMAP_REDEFINED_ATTRGROUP));
  rb_define_const(eXMLError, "SCHEMAP_REDEFINED_ATTR", INT2NUM(XML_SCHEMAP_REDEFINED_ATTR));
  rb_define_const(eXMLError, "SCHEMAP_REDEFINED_NOTATION", INT2NUM(XML_SCHEMAP_REDEFINED_NOTATION));
  rb_define_const(eXMLError, "SCHEMAP_FAILED_PARSE", INT2NUM(XML_SCHEMAP_FAILED_PARSE));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_PREFIX", INT2NUM(XML_SCHEMAP_UNKNOWN_PREFIX));
  rb_define_const(eXMLError, "SCHEMAP_DEF_AND_PREFIX", INT2NUM(XML_SCHEMAP_DEF_AND_PREFIX));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_INCLUDE_CHILD", INT2NUM(XML_SCHEMAP_UNKNOWN_INCLUDE_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_INCLUDE_SCHEMA_NOT_URI", INT2NUM(XML_SCHEMAP_INCLUDE_SCHEMA_NOT_URI));
  rb_define_const(eXMLError, "SCHEMAP_INCLUDE_SCHEMA_NO_URI", INT2NUM(XML_SCHEMAP_INCLUDE_SCHEMA_NO_URI));
  rb_define_const(eXMLError, "SCHEMAP_NOT_SCHEMA", INT2NUM(XML_SCHEMAP_NOT_SCHEMA));
  rb_define_const(eXMLError, "SCHEMAP_UNKNOWN_MEMBER_TYPE", INT2NUM(XML_SCHEMAP_UNKNOWN_MEMBER_TYPE));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_ATTR_USE", INT2NUM(XML_SCHEMAP_INVALID_ATTR_USE));
  rb_define_const(eXMLError, "SCHEMAP_RECURSIVE", INT2NUM(XML_SCHEMAP_RECURSIVE));
  rb_define_const(eXMLError, "SCHEMAP_SUPERNUMEROUS_LIST_ITEM_TYPE", INT2NUM(XML_SCHEMAP_SUPERNUMEROUS_LIST_ITEM_TYPE));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_ATTR_COMBINATION", INT2NUM(XML_SCHEMAP_INVALID_ATTR_COMBINATION));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_ATTR_INLINE_COMBINATION", INT2NUM(XML_SCHEMAP_INVALID_ATTR_INLINE_COMBINATION));
  rb_define_const(eXMLError, "SCHEMAP_MISSING_SIMPLETYPE_CHILD", INT2NUM(XML_SCHEMAP_MISSING_SIMPLETYPE_CHILD));
  rb_define_const(eXMLError, "SCHEMAP_INVALID_ATTR_NAME", INT2NUM(XML_SCHEMAP_INVALID_ATTR_NAME));
  rb_define_const(eXMLError, "SCHEMAP_REF_AND_CONTENT", INT2NUM(XML_SCHEMAP_REF_AND_CONTENT));
  rb_define_const(eXMLError, "SCHEMAP_CT_PROPS_CORRECT_1", INT2NUM(XML_SCHEMAP_CT_PROPS_CORRECT_1));
  rb_define_const(eXMLError, "SCHEMAP_CT_PROPS_CORRECT_2", INT2NUM(XML_SCHEMAP_CT_PROPS_CORRECT_2));
  rb_define_const(eXMLError, "SCHEMAP_CT_PROPS_CORRECT_3", INT2NUM(XML_SCHEMAP_CT_PROPS_CORRECT_3));
  rb_define_const(eXMLError, "SCHEMAP_CT_PROPS_CORRECT_4", INT2NUM(XML_SCHEMAP_CT_PROPS_CORRECT_4));
  rb_define_const(eXMLError, "SCHEMAP_CT_PROPS_CORRECT_5", INT2NUM(XML_SCHEMAP_CT_PROPS_CORRECT_5));
  rb_define_const(eXMLError, "SCHEMAP_DERIVATION_OK_RESTRICTION_1", INT2NUM(XML_SCHEMAP_DERIVATION_OK_RESTRICTION_1));
  rb_define_const(eXMLError, "SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_1", INT2NUM(XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_1));
  rb_define_const(eXMLError, "SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_2", INT2NUM(XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_2));
  rb_define_const(eXMLError, "SCHEMAP_DERIVATION_OK_RESTRICTION_2_2", INT2NUM(XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_2));
  rb_define_const(eXMLError, "SCHEMAP_DERIVATION_OK_RESTRICTION_3", INT2NUM(XML_SCHEMAP_DERIVATION_OK_RESTRICTION_3));
  rb_define_const(eXMLError, "SCHEMAP_WILDCARD_INVALID_NS_MEMBER", INT2NUM(XML_SCHEMAP_WILDCARD_INVALID_NS_MEMBER));
  rb_define_const(eXMLError, "SCHEMAP_INTERSECTION_NOT_EXPRESSIBLE", INT2NUM(XML_SCHEMAP_INTERSECTION_NOT_EXPRESSIBLE));
  rb_define_const(eXMLError, "SCHEMAP_UNION_NOT_EXPRESSIBLE", INT2NUM(XML_SCHEMAP_UNION_NOT_EXPRESSIBLE));
  rb_define_const(eXMLError, "SCHEMAP_SRC_IMPORT_3_1", INT2NUM(XML_SCHEMAP_SRC_IMPORT_3_1));
  rb_define_const(eXMLError, "SCHEMAP_SRC_IMPORT_3_2", INT2NUM(XML_SCHEMAP_SRC_IMPORT_3_2));
  rb_define_const(eXMLError, "SCHEMAP_DERIVATION_OK_RESTRICTION_4_1", INT2NUM(XML_SCHEMAP_DERIVATION_OK_RESTRICTION_4_1));
  rb_define_const(eXMLError, "SCHEMAP_DERIVATION_OK_RESTRICTION_4_2", INT2NUM(XML_SCHEMAP_DERIVATION_OK_RESTRICTION_4_2));
  rb_define_const(eXMLError, "SCHEMAP_DERIVATION_OK_RESTRICTION_4_3", INT2NUM(XML_SCHEMAP_DERIVATION_OK_RESTRICTION_4_3));
  rb_define_const(eXMLError, "SCHEMAP_COS_CT_EXTENDS_1_3", INT2NUM(XML_SCHEMAP_COS_CT_EXTENDS_1_3));
  rb_define_const(eXMLError, "SCHEMAV_NOROOT", INT2NUM(XML_SCHEMAV_NOROOT));
  rb_define_const(eXMLError, "SCHEMAV_UNDECLAREDELEM", INT2NUM(XML_SCHEMAV_UNDECLAREDELEM));
  rb_define_const(eXMLError, "SCHEMAV_NOTTOPLEVEL", INT2NUM(XML_SCHEMAV_NOTTOPLEVEL));
  rb_define_const(eXMLError, "SCHEMAV_MISSING", INT2NUM(XML_SCHEMAV_MISSING));
  rb_define_const(eXMLError, "SCHEMAV_WRONGELEM", INT2NUM(XML_SCHEMAV_WRONGELEM));
  rb_define_const(eXMLError, "SCHEMAV_NOTYPE", INT2NUM(XML_SCHEMAV_NOTYPE));
  rb_define_const(eXMLError, "SCHEMAV_NOROLLBACK", INT2NUM(XML_SCHEMAV_NOROLLBACK));
  rb_define_const(eXMLError, "SCHEMAV_ISABSTRACT", INT2NUM(XML_SCHEMAV_ISABSTRACT));
  rb_define_const(eXMLError, "SCHEMAV_NOTEMPTY", INT2NUM(XML_SCHEMAV_NOTEMPTY));
  rb_define_const(eXMLError, "SCHEMAV_ELEMCONT", INT2NUM(XML_SCHEMAV_ELEMCONT));
  rb_define_const(eXMLError, "SCHEMAV_HAVEDEFAULT", INT2NUM(XML_SCHEMAV_HAVEDEFAULT));
  rb_define_const(eXMLError, "SCHEMAV_NOTNILLABLE", INT2NUM(XML_SCHEMAV_NOTNILLABLE));
  rb_define_const(eXMLError, "SCHEMAV_EXTRACONTENT", INT2NUM(XML_SCHEMAV_EXTRACONTENT));
  rb_define_const(eXMLError, "SCHEMAV_INVALIDATTR", INT2NUM(XML_SCHEMAV_INVALIDATTR));
  rb_define_const(eXMLError, "SCHEMAV_INVALIDELEM", INT2NUM(XML_SCHEMAV_INVALIDELEM));
  rb_define_const(eXMLError, "SCHEMAV_NOTDETERMINIST", INT2NUM(XML_SCHEMAV_NOTDETERMINIST));
  rb_define_const(eXMLError, "SCHEMAV_CONSTRUCT", INT2NUM(XML_SCHEMAV_CONSTRUCT));
  rb_define_const(eXMLError, "SCHEMAV_INTERNAL", INT2NUM(XML_SCHEMAV_INTERNAL));
  rb_define_const(eXMLError, "SCHEMAV_NOTSIMPLE", INT2NUM(XML_SCHEMAV_NOTSIMPLE));
  rb_define_const(eXMLError, "SCHEMAV_ATTRUNKNOWN", INT2NUM(XML_SCHEMAV_ATTRUNKNOWN));
  rb_define_const(eXMLError, "SCHEMAV_ATTRINVALID", INT2NUM(XML_SCHEMAV_ATTRINVALID));
  rb_define_const(eXMLError, "SCHEMAV_VALUE", INT2NUM(XML_SCHEMAV_VALUE));
  rb_define_const(eXMLError, "SCHEMAV_FACET", INT2NUM(XML_SCHEMAV_FACET));
  rb_define_const(eXMLError, "SCHEMAV_CVC_DATATYPE_VALID_1_2_1", INT2NUM(XML_SCHEMAV_CVC_DATATYPE_VALID_1_2_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_DATATYPE_VALID_1_2_2", INT2NUM(XML_SCHEMAV_CVC_DATATYPE_VALID_1_2_2));
  rb_define_const(eXMLError, "SCHEMAV_CVC_DATATYPE_VALID_1_2_3", INT2NUM(XML_SCHEMAV_CVC_DATATYPE_VALID_1_2_3));
  rb_define_const(eXMLError, "SCHEMAV_CVC_TYPE_3_1_1", INT2NUM(XML_SCHEMAV_CVC_TYPE_3_1_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_TYPE_3_1_2", INT2NUM(XML_SCHEMAV_CVC_TYPE_3_1_2));
  rb_define_const(eXMLError, "SCHEMAV_CVC_FACET_VALID", INT2NUM(XML_SCHEMAV_CVC_FACET_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_LENGTH_VALID", INT2NUM(XML_SCHEMAV_CVC_LENGTH_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_MINLENGTH_VALID", INT2NUM(XML_SCHEMAV_CVC_MINLENGTH_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_MAXLENGTH_VALID", INT2NUM(XML_SCHEMAV_CVC_MAXLENGTH_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_MININCLUSIVE_VALID", INT2NUM(XML_SCHEMAV_CVC_MININCLUSIVE_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_MAXINCLUSIVE_VALID", INT2NUM(XML_SCHEMAV_CVC_MAXINCLUSIVE_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_MINEXCLUSIVE_VALID", INT2NUM(XML_SCHEMAV_CVC_MINEXCLUSIVE_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_MAXEXCLUSIVE_VALID", INT2NUM(XML_SCHEMAV_CVC_MAXEXCLUSIVE_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_TOTALDIGITS_VALID", INT2NUM(XML_SCHEMAV_CVC_TOTALDIGITS_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_FRACTIONDIGITS_VALID", INT2NUM(XML_SCHEMAV_CVC_FRACTIONDIGITS_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_PATTERN_VALID", INT2NUM(XML_SCHEMAV_CVC_PATTERN_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ENUMERATION_VALID", INT2NUM(XML_SCHEMAV_CVC_ENUMERATION_VALID));
  rb_define_const(eXMLError, "SCHEMAV_CVC_COMPLEX_TYPE_2_1", INT2NUM(XML_SCHEMAV_CVC_COMPLEX_TYPE_2_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_COMPLEX_TYPE_2_2", INT2NUM(XML_SCHEMAV_CVC_COMPLEX_TYPE_2_2));
  rb_define_const(eXMLError, "SCHEMAV_CVC_COMPLEX_TYPE_2_3", INT2NUM(XML_SCHEMAV_CVC_COMPLEX_TYPE_2_3));
  rb_define_const(eXMLError, "SCHEMAV_CVC_COMPLEX_TYPE_2_4", INT2NUM(XML_SCHEMAV_CVC_COMPLEX_TYPE_2_4));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_1", INT2NUM(XML_SCHEMAV_CVC_ELT_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_2", INT2NUM(XML_SCHEMAV_CVC_ELT_2));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_3_1", INT2NUM(XML_SCHEMAV_CVC_ELT_3_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_3_2_1", INT2NUM(XML_SCHEMAV_CVC_ELT_3_2_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_3_2_2", INT2NUM(XML_SCHEMAV_CVC_ELT_3_2_2));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_4_1", INT2NUM(XML_SCHEMAV_CVC_ELT_4_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_4_2", INT2NUM(XML_SCHEMAV_CVC_ELT_4_2));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_4_3", INT2NUM(XML_SCHEMAV_CVC_ELT_4_3));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_5_1_1", INT2NUM(XML_SCHEMAV_CVC_ELT_5_1_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_5_1_2", INT2NUM(XML_SCHEMAV_CVC_ELT_5_1_2));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_5_2_1", INT2NUM(XML_SCHEMAV_CVC_ELT_5_2_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_5_2_2_1", INT2NUM(XML_SCHEMAV_CVC_ELT_5_2_2_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_5_2_2_2_1", INT2NUM(XML_SCHEMAV_CVC_ELT_5_2_2_2_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_5_2_2_2_2", INT2NUM(XML_SCHEMAV_CVC_ELT_5_2_2_2_2));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_6", INT2NUM(XML_SCHEMAV_CVC_ELT_6));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ELT_7",INT2NUM(XML_SCHEMAV_CVC_ELT_7));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ATTRIBUTE_1", INT2NUM(XML_SCHEMAV_CVC_ATTRIBUTE_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ATTRIBUTE_2", INT2NUM(XML_SCHEMAV_CVC_ATTRIBUTE_2));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ATTRIBUTE_3", INT2NUM(XML_SCHEMAV_CVC_ATTRIBUTE_3));
  rb_define_const(eXMLError, "SCHEMAV_CVC_ATTRIBUTE_4", INT2NUM(XML_SCHEMAV_CVC_ATTRIBUTE_4));
  rb_define_const(eXMLError, "SCHEMAV_CVC_COMPLEX_TYPE_3_1", INT2NUM(XML_SCHEMAV_CVC_COMPLEX_TYPE_3_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_COMPLEX_TYPE_3_2_1", INT2NUM(XML_SCHEMAV_CVC_COMPLEX_TYPE_3_2_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_COMPLEX_TYPE_3_2_2", INT2NUM(XML_SCHEMAV_CVC_COMPLEX_TYPE_3_2_2));
  rb_define_const(eXMLError, "SCHEMAV_CVC_COMPLEX_TYPE_4", INT2NUM(XML_SCHEMAV_CVC_COMPLEX_TYPE_4));
  rb_define_const(eXMLError, "SCHEMAV_CVC_COMPLEX_TYPE_5_1", INT2NUM(XML_SCHEMAV_CVC_COMPLEX_TYPE_5_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_COMPLEX_TYPE_5_2", INT2NUM(XML_SCHEMAV_CVC_COMPLEX_TYPE_5_2));
  rb_define_const(eXMLError, "SCHEMAV_ELEMENT_CONTENT", INT2NUM(XML_SCHEMAV_ELEMENT_CONTENT));
  rb_define_const(eXMLError, "SCHEMAV_DOCUMENT_ELEMENT_MISSING", INT2NUM(XML_SCHEMAV_DOCUMENT_ELEMENT_MISSING));
  rb_define_const(eXMLError, "SCHEMAV_CVC_COMPLEX_TYPE_1", INT2NUM(XML_SCHEMAV_CVC_COMPLEX_TYPE_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_AU", INT2NUM(XML_SCHEMAV_CVC_AU));
  rb_define_const(eXMLError, "SCHEMAV_CVC_TYPE_1", INT2NUM(XML_SCHEMAV_CVC_TYPE_1));
  rb_define_const(eXMLError, "SCHEMAV_CVC_TYPE_2", INT2NUM(XML_SCHEMAV_CVC_TYPE_2));
#if LIBXML_VERSION >= 20618
  rb_define_const(eXMLError, "SCHEMAV_CVC_IDC", INT2NUM(XML_SCHEMAV_CVC_IDC));
  rb_define_const(eXMLError, "SCHEMAV_CVC_WILDCARD", INT2NUM(XML_SCHEMAV_CVC_WILDCARD));
#endif
#if LIBXML_VERSION >= 20631
  rb_define_const(eXMLError, "SCHEMAV_MISC", INT2NUM(XML_SCHEMAV_MISC));
#endif
  rb_define_const(eXMLError, "XPTR_UNKNOWN_SCHEME", INT2NUM(XML_XPTR_UNKNOWN_SCHEME));
  rb_define_const(eXMLError, "XPTR_CHILDSEQ_START", INT2NUM(XML_XPTR_CHILDSEQ_START));
  rb_define_const(eXMLError, "XPTR_EVAL_FAILED", INT2NUM(XML_XPTR_EVAL_FAILED));
  rb_define_const(eXMLError, "XPTR_EXTRA_OBJECTS", INT2NUM(XML_XPTR_EXTRA_OBJECTS));
  rb_define_const(eXMLError, "C14N_CREATE_CTXT", INT2NUM(XML_C14N_CREATE_CTXT));
  rb_define_const(eXMLError, "C14N_REQUIRES_UTF8", INT2NUM(XML_C14N_REQUIRES_UTF8));
  rb_define_const(eXMLError, "C14N_CREATE_STACK",
      INT2NUM(XML_C14N_CREATE_STACK));
  rb_define_const(eXMLError, "C14N_INVALID_NODE",
      INT2NUM(XML_C14N_INVALID_NODE));
#if LIBXML_VERSION >= 20619
  rb_define_const(eXMLError, "C14N_UNKNOW_NODE", INT2NUM(XML_C14N_UNKNOW_NODE));
  rb_define_const(eXMLError, "C14N_RELATIVE_NAMESPACE", INT2NUM(XML_C14N_RELATIVE_NAMESPACE));
#endif
  rb_define_const(eXMLError, "FTP_PASV_ANSWER", INT2NUM(XML_FTP_PASV_ANSWER));
  rb_define_const(eXMLError, "FTP_EPSV_ANSWER", INT2NUM(XML_FTP_EPSV_ANSWER));
  rb_define_const(eXMLError, "FTP_ACCNT", INT2NUM(XML_FTP_ACCNT));
#if LIBXML_VERSION >= 20618
  rb_define_const(eXMLError, "FTP_URL_SYNTAX", INT2NUM(XML_FTP_URL_SYNTAX));
#endif
  rb_define_const(eXMLError, "HTTP_URL_SYNTAX", INT2NUM(XML_HTTP_URL_SYNTAX));
  rb_define_const(eXMLError, "HTTP_USE_IP", INT2NUM(XML_HTTP_USE_IP));
  rb_define_const(eXMLError, "HTTP_UNKNOWN_HOST", INT2NUM(XML_HTTP_UNKNOWN_HOST));
  rb_define_const(eXMLError, "SCHEMAP_SRC_SIMPLE_TYPE_1", INT2NUM(XML_SCHEMAP_SRC_SIMPLE_TYPE_1));
  rb_define_const(eXMLError, "SCHEMAP_SRC_SIMPLE_TYPE_2", INT2NUM(XML_SCHEMAP_SRC_SIMPLE_TYPE_2));
  rb_define_const(eXMLError, "SCHEMAP_SRC_SIMPLE_TYPE_3", INT2NUM(XML_SCHEMAP_SRC_SIMPLE_TYPE_3));
  rb_define_const(eXMLError, "SCHEMAP_SRC_SIMPLE_TYPE_4", INT2NUM(XML_SCHEMAP_SRC_SIMPLE_TYPE_4));
  rb_define_const(eXMLError, "SCHEMAP_SRC_RESOLVE", INT2NUM(XML_SCHEMAP_SRC_RESOLVE));
  rb_define_const(eXMLError, "SCHEMAP_SRC_RESTRICTION_BASE_OR_SIMPLETYPE", INT2NUM(XML_SCHEMAP_SRC_RESTRICTION_BASE_OR_SIMPLETYPE));
  rb_define_const(eXMLError, "SCHEMAP_SRC_LIST_ITEMTYPE_OR_SIMPLETYPE", INT2NUM(XML_SCHEMAP_SRC_LIST_ITEMTYPE_OR_SIMPLETYPE));
  rb_define_const(eXMLError, "SCHEMAP_SRC_UNION_MEMBERTYPES_OR_SIMPLETYPES", INT2NUM(XML_SCHEMAP_SRC_UNION_MEMBERTYPES_OR_SIMPLETYPES));
  rb_define_const(eXMLError, "SCHEMAP_ST_PROPS_CORRECT_1", INT2NUM(XML_SCHEMAP_ST_PROPS_CORRECT_1));
  rb_define_const(eXMLError, "SCHEMAP_ST_PROPS_CORRECT_2", INT2NUM(XML_SCHEMAP_ST_PROPS_CORRECT_2));
  rb_define_const(eXMLError, "SCHEMAP_ST_PROPS_CORRECT_3", INT2NUM(XML_SCHEMAP_ST_PROPS_CORRECT_3));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_1_1", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_1_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_1_2", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_1_2));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_1_3_1", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_1_3_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_1_3_2", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_1_3_2));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_2_1", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_2_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_2_3_1_1", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_2_3_1_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_2_3_1_2", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_2_3_1_2));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_2_3_2_1", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_2_3_2_2", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_2));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_2_3_2_3", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_3));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_2_3_2_4", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_4));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_2_3_2_5", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_2_3_2_5));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_3_1", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_3_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_3_3_1", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_3_3_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_3_3_1_2", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_3_3_1_2));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_3_3_2_2", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_2));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_3_3_2_1", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_3_3_2_3", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_3));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_3_3_2_4", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_4));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_RESTRICTS_3_3_2_5", INT2NUM(XML_SCHEMAP_COS_ST_RESTRICTS_3_3_2_5));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_DERIVED_OK_2_1", INT2NUM(XML_SCHEMAP_COS_ST_DERIVED_OK_2_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_ST_DERIVED_OK_2_2", INT2NUM(XML_SCHEMAP_COS_ST_DERIVED_OK_2_2));
  rb_define_const(eXMLError, "SCHEMAP_S4S_ELEM_NOT_ALLOWED", INT2NUM(XML_SCHEMAP_S4S_ELEM_NOT_ALLOWED));
  rb_define_const(eXMLError, "SCHEMAP_S4S_ELEM_MISSING", INT2NUM(XML_SCHEMAP_S4S_ELEM_MISSING));
  rb_define_const(eXMLError, "SCHEMAP_S4S_ATTR_NOT_ALLOWED", INT2NUM(XML_SCHEMAP_S4S_ATTR_NOT_ALLOWED));
  rb_define_const(eXMLError, "SCHEMAP_S4S_ATTR_MISSING", INT2NUM(XML_SCHEMAP_S4S_ATTR_MISSING));
  rb_define_const(eXMLError, "SCHEMAP_S4S_ATTR_INVALID_VALUE", INT2NUM(XML_SCHEMAP_S4S_ATTR_INVALID_VALUE));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ELEMENT_1", INT2NUM(XML_SCHEMAP_SRC_ELEMENT_1));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ELEMENT_2_1", INT2NUM(XML_SCHEMAP_SRC_ELEMENT_2_1));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ELEMENT_2_2", INT2NUM(XML_SCHEMAP_SRC_ELEMENT_2_2));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ELEMENT_3", INT2NUM(XML_SCHEMAP_SRC_ELEMENT_3));
  rb_define_const(eXMLError, "SCHEMAP_P_PROPS_CORRECT_1", INT2NUM(XML_SCHEMAP_P_PROPS_CORRECT_1));
  rb_define_const(eXMLError, "SCHEMAP_P_PROPS_CORRECT_2_1", INT2NUM(XML_SCHEMAP_P_PROPS_CORRECT_2_1));
  rb_define_const(eXMLError, "SCHEMAP_P_PROPS_CORRECT_2_2", INT2NUM(XML_SCHEMAP_P_PROPS_CORRECT_2_2));
  rb_define_const(eXMLError, "SCHEMAP_E_PROPS_CORRECT_2", INT2NUM(XML_SCHEMAP_E_PROPS_CORRECT_2));
  rb_define_const(eXMLError, "SCHEMAP_E_PROPS_CORRECT_3", INT2NUM(XML_SCHEMAP_E_PROPS_CORRECT_3));
  rb_define_const(eXMLError, "SCHEMAP_E_PROPS_CORRECT_4", INT2NUM(XML_SCHEMAP_E_PROPS_CORRECT_4));
  rb_define_const(eXMLError, "SCHEMAP_E_PROPS_CORRECT_5", INT2NUM(XML_SCHEMAP_E_PROPS_CORRECT_5));
  rb_define_const(eXMLError, "SCHEMAP_E_PROPS_CORRECT_6", INT2NUM(XML_SCHEMAP_E_PROPS_CORRECT_6));
  rb_define_const(eXMLError, "SCHEMAP_SRC_INCLUDE", INT2NUM(XML_SCHEMAP_SRC_INCLUDE));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ATTRIBUTE_1", INT2NUM(XML_SCHEMAP_SRC_ATTRIBUTE_1));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ATTRIBUTE_2", INT2NUM(XML_SCHEMAP_SRC_ATTRIBUTE_2));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ATTRIBUTE_3_1", INT2NUM(XML_SCHEMAP_SRC_ATTRIBUTE_3_1));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ATTRIBUTE_3_2", INT2NUM(XML_SCHEMAP_SRC_ATTRIBUTE_3_2));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ATTRIBUTE_4", INT2NUM(XML_SCHEMAP_SRC_ATTRIBUTE_4));
  rb_define_const(eXMLError, "SCHEMAP_NO_XMLNS", INT2NUM(XML_SCHEMAP_NO_XMLNS));
  rb_define_const(eXMLError, "SCHEMAP_NO_XSI", INT2NUM(XML_SCHEMAP_NO_XSI));
  rb_define_const(eXMLError, "SCHEMAP_COS_VALID_DEFAULT_1", INT2NUM(XML_SCHEMAP_COS_VALID_DEFAULT_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_VALID_DEFAULT_2_1", INT2NUM(XML_SCHEMAP_COS_VALID_DEFAULT_2_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_VALID_DEFAULT_2_2_1", INT2NUM(XML_SCHEMAP_COS_VALID_DEFAULT_2_2_1));
  rb_define_const(eXMLError, "SCHEMAP_COS_VALID_DEFAULT_2_2_2", INT2NUM(XML_SCHEMAP_COS_VALID_DEFAULT_2_2_2));
  rb_define_const(eXMLError, "SCHEMAP_CVC_SIMPLE_TYPE", INT2NUM(XML_SCHEMAP_CVC_SIMPLE_TYPE));
  rb_define_const(eXMLError, "SCHEMAP_COS_CT_EXTENDS_1_1", INT2NUM(XML_SCHEMAP_COS_CT_EXTENDS_1_1));
  rb_define_const(eXMLError, "SCHEMAP_SRC_IMPORT_1_1", INT2NUM(XML_SCHEMAP_SRC_IMPORT_1_1));
  rb_define_const(eXMLError, "SCHEMAP_SRC_IMPORT_1_2", INT2NUM(XML_SCHEMAP_SRC_IMPORT_1_2));
  rb_define_const(eXMLError, "SCHEMAP_SRC_IMPORT_2", INT2NUM(XML_SCHEMAP_SRC_IMPORT_2));
  rb_define_const(eXMLError, "SCHEMAP_SRC_IMPORT_2_1", INT2NUM(XML_SCHEMAP_SRC_IMPORT_2_1));
  rb_define_const(eXMLError, "SCHEMAP_SRC_IMPORT_2_2", INT2NUM(XML_SCHEMAP_SRC_IMPORT_2_2));
  rb_define_const(eXMLError, "SCHEMAP_INTERNAL", INT2NUM(XML_SCHEMAP_INTERNAL));
  rb_define_const(eXMLError, "SCHEMAP_NOT_DETERMINISTIC", INT2NUM(XML_SCHEMAP_NOT_DETERMINISTIC));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ATTRIBUTE_GROUP_1", INT2NUM(XML_SCHEMAP_SRC_ATTRIBUTE_GROUP_1));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ATTRIBUTE_GROUP_2", INT2NUM(XML_SCHEMAP_SRC_ATTRIBUTE_GROUP_2));
  rb_define_const(eXMLError, "SCHEMAP_SRC_ATTRIBUTE_GROUP_3", INT2NUM(XML_SCHEMAP_SRC_ATTRIBUTE_GROUP_3));
  rb_define_const(eXMLError, "SCHEMAP_MG_PROPS_CORRECT_1", INT2NUM(XML_SCHEMAP_MG_PROPS_CORRECT_1));
  rb_define_const(eXMLError, "SCHEMAP_MG_PROPS_CORRECT_2", INT2NUM(XML_SCHEMAP_MG_PROPS_CORRECT_2));
  rb_define_const(eXMLError, "SCHEMAP_SRC_CT_1", INT2NUM(XML_SCHEMAP_SRC_CT_1));
  rb_define_const(eXMLError, "SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_3", INT2NUM(XML_SCHEMAP_DERIVATION_OK_RESTRICTION_2_1_3));
  rb_define_const(eXMLError, "SCHEMAP_AU_PROPS_CORRECT_2", INT2NUM(XML_SCHEMAP_AU_PROPS_CORRECT_2));
  rb_define_const(eXMLError, "SCHEMAP_A_PROPS_CORRECT_2", INT2NUM(XML_SCHEMAP_A_PROPS_CORRECT_2));
#if LIBXML_VERSION >= 20620
  rb_define_const(eXMLError, "SCHEMAP_C_PROPS_CORRECT", INT2NUM(XML_SCHEMAP_C_PROPS_CORRECT));
#endif
#if LIBXML_VERSION >= 20621
  rb_define_const(eXMLError, "SCHEMAP_SRC_REDEFINE", INT2NUM(XML_SCHEMAP_SRC_REDEFINE));
  rb_define_const(eXMLError, "SCHEMAP_SRC_IMPORT", INT2NUM(XML_SCHEMAP_SRC_IMPORT));
  rb_define_const(eXMLError, "SCHEMAP_WARN_SKIP_SCHEMA", INT2NUM(XML_SCHEMAP_WARN_SKIP_SCHEMA));
  rb_define_const(eXMLError, "SCHEMAP_WARN_UNLOCATED_SCHEMA", INT2NUM(XML_SCHEMAP_WARN_UNLOCATED_SCHEMA));
  rb_define_const(eXMLError, "SCHEMAP_WARN_ATTR_REDECL_PROH", INT2NUM(XML_SCHEMAP_WARN_ATTR_REDECL_PROH));
  rb_define_const(eXMLError, "SCHEMAP_WARN_ATTR_POINTLESS_PROH", INT2NUM(XML_SCHEMAP_WARN_ATTR_POINTLESS_PROH));
#endif
#if LIBXML_VERSION >= 20623
  rb_define_const(eXMLError, "SCHEMAP_AG_PROPS_CORRECT", INT2NUM(XML_SCHEMAP_AG_PROPS_CORRECT));
  rb_define_const(eXMLError, "SCHEMAP_COS_CT_EXTENDS_1_2", INT2NUM(XML_SCHEMAP_COS_CT_EXTENDS_1_2));
  rb_define_const(eXMLError, "SCHEMAP_AU_PROPS_CORRECT", INT2NUM(XML_SCHEMAP_AU_PROPS_CORRECT));
  rb_define_const(eXMLError, "SCHEMAP_A_PROPS_CORRECT_3", INT2NUM(XML_SCHEMAP_A_PROPS_CORRECT_3));
  rb_define_const(eXMLError, "SCHEMAP_COS_ALL_LIMITED", INT2NUM(XML_SCHEMAP_COS_ALL_LIMITED));
#endif
#if LIBXML_VERSION >= 20632
  rb_define_const(eXMLError, "SCHEMATRONV_ASSERT", INT2NUM(XML_SCHEMATRONV_ASSERT));
  rb_define_const(eXMLError, "SCHEMATRONV_REPORT", INT2NUM(XML_SCHEMATRONV_REPORT));
#endif
#if LIBXML_VERSION >= 20618
  rb_define_const(eXMLError, "MODULE_OPEN", INT2NUM(XML_MODULE_OPEN));
  rb_define_const(eXMLError, "MODULE_CLOSE", INT2NUM(XML_MODULE_CLOSE));
#endif
  rb_define_const(eXMLError, "CHECK_FOUND_ELEMENT", INT2NUM(XML_CHECK_FOUND_ELEMENT));
  rb_define_const(eXMLError, "CHECK_FOUND_ATTRIBUTE", INT2NUM(XML_CHECK_FOUND_ATTRIBUTE));
  rb_define_const(eXMLError, "CHECK_FOUND_TEXT", INT2NUM(XML_CHECK_FOUND_TEXT));
  rb_define_const(eXMLError, "CHECK_FOUND_CDATA",INT2NUM(XML_CHECK_FOUND_CDATA));
  rb_define_const(eXMLError, "CHECK_FOUND_ENTITYREF", INT2NUM(XML_CHECK_FOUND_ENTITYREF));
  rb_define_const(eXMLError, "CHECK_FOUND_ENTITY", INT2NUM(XML_CHECK_FOUND_ENTITY));
  rb_define_const(eXMLError, "CHECK_FOUND_PI", INT2NUM(XML_CHECK_FOUND_PI));
  rb_define_const(eXMLError, "CHECK_FOUND_COMMENT", INT2NUM(XML_CHECK_FOUND_COMMENT));
  rb_define_const(eXMLError, "CHECK_FOUND_DOCTYPE", INT2NUM(XML_CHECK_FOUND_DOCTYPE));
  rb_define_const(eXMLError, "CHECK_FOUND_FRAGMENT", INT2NUM(XML_CHECK_FOUND_FRAGMENT));
  rb_define_const(eXMLError, "CHECK_FOUND_NOTATION", INT2NUM(XML_CHECK_FOUND_NOTATION));
  rb_define_const(eXMLError, "CHECK_UNKNOWN_NODE", INT2NUM(XML_CHECK_UNKNOWN_NODE));
  rb_define_const(eXMLError, "CHECK_ENTITY_TYPE", INT2NUM(XML_CHECK_ENTITY_TYPE));
  rb_define_const(eXMLError, "CHECK_NO_PARENT", INT2NUM(XML_CHECK_NO_PARENT));
  rb_define_const(eXMLError, "CHECK_NO_DOC", INT2NUM(XML_CHECK_NO_DOC));
  rb_define_const(eXMLError, "CHECK_NO_NAME", INT2NUM(XML_CHECK_NO_NAME));
  rb_define_const(eXMLError, "CHECK_NO_ELEM", INT2NUM(XML_CHECK_NO_ELEM));
  rb_define_const(eXMLError, "CHECK_WRONG_DOC", INT2NUM(XML_CHECK_WRONG_DOC));
  rb_define_const(eXMLError, "CHECK_NO_PREV", INT2NUM(XML_CHECK_NO_PREV));
  rb_define_const(eXMLError, "CHECK_WRONG_PREV", INT2NUM(XML_CHECK_WRONG_PREV));
  rb_define_const(eXMLError, "CHECK_NO_NEXT", INT2NUM(XML_CHECK_NO_NEXT));
  rb_define_const(eXMLError, "CHECK_WRONG_NEXT", INT2NUM(XML_CHECK_WRONG_NEXT));
  rb_define_const(eXMLError, "CHECK_NOT_DTD", INT2NUM(XML_CHECK_NOT_DTD));
  rb_define_const(eXMLError, "CHECK_NOT_ATTR", INT2NUM(XML_CHECK_NOT_ATTR));
  rb_define_const(eXMLError, "CHECK_NOT_ATTR_DECL", INT2NUM(XML_CHECK_NOT_ATTR_DECL));
  rb_define_const(eXMLError, "CHECK_NOT_ELEM_DECL", INT2NUM(XML_CHECK_NOT_ELEM_DECL));
  rb_define_const(eXMLError, "CHECK_NOT_ENTITY_DECL", INT2NUM(XML_CHECK_NOT_ENTITY_DECL));
  rb_define_const(eXMLError, "CHECK_NOT_NS_DECL", INT2NUM(XML_CHECK_NOT_NS_DECL));
  rb_define_const(eXMLError, "CHECK_NO_HREF", INT2NUM(XML_CHECK_NO_HREF));
  rb_define_const(eXMLError, "CHECK_WRONG_PARENT", INT2NUM(XML_CHECK_WRONG_PARENT));
  rb_define_const(eXMLError, "CHECK_NS_SCOPE", INT2NUM(XML_CHECK_NS_SCOPE));
  rb_define_const(eXMLError, "CHECK_NS_ANCESTOR", INT2NUM(XML_CHECK_NS_ANCESTOR));
  rb_define_const(eXMLError, "CHECK_NOT_UTF8", INT2NUM(XML_CHECK_NOT_UTF8));
  rb_define_const(eXMLError, "CHECK_NO_DICT", INT2NUM(XML_CHECK_NO_DICT));
  rb_define_const(eXMLError, "CHECK_NOT_NCNAME", INT2NUM(XML_CHECK_NOT_NCNAME));
  rb_define_const(eXMLError, "CHECK_OUTSIDE_DICT", INT2NUM(XML_CHECK_OUTSIDE_DICT));
  rb_define_const(eXMLError, "CHECK_WRONG_NAME", INT2NUM(XML_CHECK_WRONG_NAME));
#if LIBXML_VERSION >= 20621
  rb_define_const(eXMLError, "CHECK_NAME_NOT_NULL", INT2NUM(XML_CHECK_NAME_NOT_NULL));
  rb_define_const(eXMLError, "I18N_NO_NAME", INT2NUM(XML_I18N_NO_NAME));
  rb_define_const(eXMLError, "I18N_NO_HANDLER", INT2NUM(XML_I18N_NO_HANDLER));
  rb_define_const(eXMLError, "I18N_EXCESS_HANDLER", INT2NUM(XML_I18N_EXCESS_HANDLER));
  rb_define_const(eXMLError, "I18N_CONV_FAILED", INT2NUM(XML_I18N_CONV_FAILED));
  rb_define_const(eXMLError, "I18N_NO_OUTPUT", INT2NUM(XML_I18N_NO_OUTPUT));
#endif
}
