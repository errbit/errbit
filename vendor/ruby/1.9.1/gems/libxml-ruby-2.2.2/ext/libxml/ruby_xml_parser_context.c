/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"
#include "ruby_xml_parser_context.h"

VALUE cXMLParserContext;
static ID IO_ATTR;

/*
 * Document-class: LibXML::XML::Parser::Context
 *
 * The XML::Parser::Context class provides in-depth control over how
 * a document is parsed.
 */

static void rxml_parser_context_free(xmlParserCtxtPtr ctxt)
{
  xmlFreeParserCtxt(ctxt);
}

static VALUE rxml_parser_context_wrap(xmlParserCtxtPtr ctxt)
{
  return Data_Wrap_Struct(cXMLParserContext, NULL, rxml_parser_context_free, ctxt);
}


static VALUE rxml_parser_context_alloc(VALUE klass)
{
  xmlParserCtxtPtr ctxt = xmlNewParserCtxt();
  return Data_Wrap_Struct(klass, NULL, rxml_parser_context_free, ctxt);
}

/* call-seq:
 *    XML::Parser::Context.document(document) -> XML::Parser::Context
 *
 * Creates a new parser context based on the specified document.
 *
 * Parameters:
 *
 *  document - An XML::Document instance.
 */
static VALUE rxml_parser_context_document(VALUE klass, VALUE document)
{
  xmlParserCtxtPtr ctxt;
  xmlDocPtr xdoc;
  xmlChar *buffer; 
  int length;

  if (rb_obj_is_kind_of(document, cXMLDocument) == Qfalse)
    rb_raise(rb_eTypeError, "Must pass an XML::Document object");

  Data_Get_Struct(document, xmlDoc, xdoc);
  xmlDocDumpFormatMemoryEnc(xdoc, &buffer, &length, xdoc->encoding, 0);

  ctxt = xmlCreateDocParserCtxt(buffer);

  if (!ctxt)
    rxml_raise(&xmlLastError);

  /* This is annoying, but xmlInitParserCtxt (called indirectly above) and 
     xmlCtxtUseOptionsInternal (called below) initialize slightly different
     context options, in particular XML_PARSE_NODICT which xmlInitParserCtxt
     sets to 0 and xmlCtxtUseOptionsInternal sets to 1.  So we have to call both. */
  xmlCtxtUseOptions(ctxt, rxml_libxml_default_options());

  return rxml_parser_context_wrap(ctxt);
}

/* call-seq:
 *    XML::Parser::Context.file(file) -> XML::Parser::Context
 *
 * Creates a new parser context based on the specified file or uri.
 *
 * Parameters:
 *
 *  file - A filename or uri.
*/
static VALUE rxml_parser_context_file(VALUE klass, VALUE file)
{
  xmlParserCtxtPtr ctxt = xmlCreateURLParserCtxt(StringValuePtr(file), 0);

  if (!ctxt)
    rxml_raise(&xmlLastError);

  /* This is annoying, but xmlInitParserCtxt (called indirectly above) and 
     xmlCtxtUseOptionsInternal (called below) initialize slightly different
     context options, in particular XML_PARSE_NODICT which xmlInitParserCtxt
     sets to 0 and xmlCtxtUseOptionsInternal sets to 1.  So we have to call both. */
  xmlCtxtUseOptions(ctxt, rxml_libxml_default_options());

  return rxml_parser_context_wrap(ctxt);
}

/* call-seq:
 *    XML::Parser::Context.string(string) -> XML::Parser::Context
 *
 * Creates a new parser context based on the specified string.
 *
 * Parameters:
 *
 *  string - A string that contains the data to parse.
*/
static VALUE rxml_parser_context_string(VALUE klass, VALUE string)
{
  xmlParserCtxtPtr ctxt;
  Check_Type(string, T_STRING);

  if (RSTRING_LEN(string) == 0)
    rb_raise(rb_eArgError, "Must specify a string with one or more characters");

  ctxt = xmlCreateMemoryParserCtxt(StringValuePtr(string),
                                   RSTRING_LEN(string));
  
  if (!ctxt)
    rxml_raise(&xmlLastError);

  /* This is annoying, but xmlInitParserCtxt (called indirectly above) and 
     xmlCtxtUseOptionsInternal (called below) initialize slightly different
     context options, in particular XML_PARSE_NODICT which xmlInitParserCtxt
     sets to 0 and xmlCtxtUseOptionsInternal sets to 1.  So we have to call both. */
  xmlCtxtUseOptions(ctxt, rxml_libxml_default_options());

  return rxml_parser_context_wrap(ctxt);
}

/* call-seq:
 *    XML::Parser::Context.io(io) -> XML::Parser::Context
 *
 * Creates a new parser context based on the specified io object.
 *
 * Parameters:
 *
 *  io - A ruby IO object.
*/
static VALUE rxml_parser_context_io(VALUE klass, VALUE io)
{
  VALUE result;
  xmlParserCtxtPtr ctxt;
  xmlParserInputBufferPtr input;
  xmlParserInputPtr stream;

  if (NIL_P(io))
    rb_raise(rb_eTypeError, "Must pass in an IO object");

  input = xmlParserInputBufferCreateIO((xmlInputReadCallback) rxml_read_callback, NULL,
                                       (void*)io, XML_CHAR_ENCODING_NONE);
    
  ctxt = xmlNewParserCtxt();

  if (!ctxt)
  {
    xmlFreeParserInputBuffer(input);
    rxml_raise(&xmlLastError);
  }

  /* This is annoying, but xmlInitParserCtxt (called indirectly above) and 
     xmlCtxtUseOptionsInternal (called below) initialize slightly different
     context options, in particular XML_PARSE_NODICT which xmlInitParserCtxt
     sets to 0 and xmlCtxtUseOptionsInternal sets to 1.  So we have to call both. */
  xmlCtxtUseOptions(ctxt, rxml_libxml_default_options());

  stream = xmlNewIOInputStream(ctxt, input, XML_CHAR_ENCODING_NONE);

  if (!stream)
  {
    xmlFreeParserInputBuffer(input);
    xmlFreeParserCtxt(ctxt);
    rxml_raise(&xmlLastError);
  }
  inputPush(ctxt, stream);
  result = rxml_parser_context_wrap(ctxt);

  /* Attach io object to parser so it won't get freed.*/
  rb_ivar_set(result, IO_ATTR, io);

  return result;
}

/*
 * call-seq:
 *    context.base_uri -> "http:://libxml.org"
 *
 * Obtain the base url for this parser context.
 */
static VALUE rxml_parser_context_base_uri_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->input && ctxt->input->filename)
    return rxml_new_cstr(ctxt->input->filename, ctxt->encoding);
  else
    return Qnil;
}

/*
 * call-seq:
 *    context.base_uri = "http:://libxml.org"
 *
 * Sets the base url for this parser context.
 */
static VALUE rxml_parser_context_base_uri_set(VALUE self, VALUE url)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  Check_Type(url, T_STRING);

  if (ctxt->input && !ctxt->input->filename)
  {
    const xmlChar * xurl = StringValuePtr(url);
    ctxt->input->filename = (char *) xmlStrdup(xurl);
  }
  return self;
}

/*
 * call-seq:
 *    context.close -> nil
 *
 * Closes the underlying input streams.  This is useful when parsing a large amount of
 * files and you want to close the files without relying on Ruby's garbage collector
 * to run.
 */
static VALUE rxml_parser_context_close(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  xmlParserInputPtr xinput;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  while ((xinput = inputPop(ctxt)) != NULL)
  {
	 xmlFreeInputStream(xinput);
  }
  return Qnil;
}

/*
 * call-seq:
 *    context.data_directory -> "dir"
 *
 * Obtain the data directory associated with this context.
 */
static VALUE rxml_parser_context_data_directory_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->directory == NULL)
    return (Qnil);
  else
    return (rxml_new_cstr(ctxt->directory, ctxt->encoding));
}

/*
 * call-seq:
 *    context.depth -> num
 *
 * Obtain the depth of this context.
 */
static VALUE rxml_parser_context_depth_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->depth));
}

/*
 * call-seq:
 *    context.disable_cdata? -> (true|false)
 *
 * Determine whether CDATA nodes will be created in this context.
 */
static VALUE rxml_parser_context_disable_cdata_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  /* LibXML controls this internally with the default SAX handler. */
  if (ctxt->sax && ctxt->sax->cdataBlock)
    return (Qfalse);
  else
    return (Qtrue);
}

/*
 * call-seq:
 *    context.disable_cdata = (true|false)
 *
 * Control whether CDATA nodes will be created in this context.
 */
static VALUE rxml_parser_context_disable_cdata_set(VALUE self, VALUE bool)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->sax == NULL)
    rb_raise(rb_eRuntimeError, "Sax handler is not yet set");

  /* LibXML controls this internally with the default SAX handler. */ 
  if (bool)
    ctxt->sax->cdataBlock = NULL;
  else
    ctxt->sax->cdataBlock = xmlDefaultSAXHandler.cdataBlock;

  return bool;
}

/*
 * call-seq:
 *    context.disable_sax? -> (true|false)
 *
 * Determine whether SAX-based processing is disabled
 * in this context.
 */
static VALUE rxml_parser_context_disable_sax_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->disableSAX)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.docbook? -> (true|false)
 *
 * Determine whether this is a docbook context.
 */
static VALUE rxml_parser_context_docbook_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->html == 2) // TODO check this
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.encoding -> XML::Encoding::UTF_8
 *
 * Obtain the character encoding identifier used in
 * this context.
 */
static VALUE rxml_parser_context_encoding_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);
  return INT2NUM(xmlParseCharEncoding(ctxt->encoding));
}

/*
 * call-seq:
 *    context.encoding = XML::Encoding::UTF_8
 *
 * Sets the character encoding for this context.
 */
static VALUE rxml_parser_context_encoding_set(VALUE self, VALUE encoding)
{
  xmlParserCtxtPtr ctxt;
  int result;
  const char* xencoding = xmlGetCharEncodingName((xmlCharEncoding)NUM2INT(encoding));
  xmlCharEncodingHandlerPtr hdlr = xmlFindCharEncodingHandler(xencoding);
  
  if (!hdlr)
    rb_raise(rb_eArgError, "Unknown encoding: %i", NUM2INT(encoding));

  Data_Get_Struct(self, xmlParserCtxt, ctxt);
  result = xmlSwitchToEncoding(ctxt, hdlr);

  if (result != 0)
    rxml_raise(&xmlLastError);

  if (ctxt->encoding != NULL)
    xmlFree((xmlChar *) ctxt->encoding);

  ctxt->encoding = xmlStrdup((const xmlChar *) xencoding);
  return self;
}

/*
 * call-seq:
 *    context.errno -> num
 *
 * Obtain the last-error number in this context.
 */
static VALUE rxml_parser_context_errno_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->errNo));
}

/*
 * call-seq:
 *    context.html? -> (true|false)
 *
 * Determine whether this is an html context.
 */
static VALUE rxml_parser_context_html_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->html == 1)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.max_num_streams -> num
 *
 * Obtain the limit on the number of IO streams opened in
 * this context.
 */
static VALUE rxml_parser_context_io_max_num_streams_get(VALUE self)
{
  // TODO alias to max_streams and dep this?
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->inputMax));
}

/*
 * call-seq:
 *    context.num_streams -> "dir"
 *
 * Obtain the actual number of IO streams in this
 * context.
 */
static VALUE rxml_parser_context_io_num_streams_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->inputNr));
}

/*
 * call-seq:
 *    context.keep_blanks? -> (true|false)
 *
 * Determine whether parsers in this context retain
 * whitespace.
 */
static VALUE rxml_parser_context_keep_blanks_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->keepBlanks)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.name_depth -> num
 *
 * Obtain the name depth for this context.
 */
static VALUE rxml_parser_context_name_depth_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->nameNr));
}

/*
 * call-seq:
 *    context.name_depth_max -> num
 *
 * Obtain the maximum name depth for this context.
 */
static VALUE rxml_parser_context_name_depth_max_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->nameMax));
}

/*
 * call-seq:
 *    context.name_node -> "name"
 *
 * Obtain the name node for this context.
 */
static VALUE rxml_parser_context_name_node_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->name == NULL)
    return (Qnil);
  else
    return (rxml_new_cstr((const char*) ctxt->name, ctxt->encoding));
}

/*
 * call-seq:
 *    context.name_tab -> ["name", ..., "name"]
 *
 * Obtain the name table for this context.
 */
static VALUE rxml_parser_context_name_tab_get(VALUE self)
{
  int i;
  xmlParserCtxtPtr ctxt;
  VALUE tab_ary;

  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->nameTab == NULL)
    return (Qnil);

  tab_ary = rb_ary_new();

  for (i = (ctxt->nameNr - 1); i >= 0; i--)
  {
    if (ctxt->nameTab[i] == NULL)
      continue;
    else
      rb_ary_push(tab_ary, rxml_new_cstr((const char*) ctxt->nameTab[i], ctxt->encoding));
  }

  return (tab_ary);
}

/*
 * call-seq:
 *    context.node_depth -> num
 *
 * Obtain the node depth for this context.
 */
static VALUE rxml_parser_context_node_depth_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->nodeNr));
}

/*
 * call-seq:
 *    context.node -> node
 *
 * Obtain the root node of this context.
 */
static VALUE rxml_parser_context_node_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->node == NULL)
    return (Qnil);
  else
    return (rxml_node_wrap(ctxt->node));
}

/*
 * call-seq:
 *    context.node_depth_max -> num
 *
 * Obtain the maximum node depth for this context.
 */
static VALUE rxml_parser_context_node_depth_max_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->nodeMax));
}

/*
 * call-seq:
 *    context.num_chars -> num
 *
 * Obtain the number of characters in this context.
 */
static VALUE rxml_parser_context_num_chars_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (LONG2NUM(ctxt->nbChars));
}


/*
 * call-seq:
 *    context.options > XML::Parser::Options::NOENT
 *
 * Returns the parser options for this context.  Multiple
 * options can be combined by using Bitwise OR (|).
 */
static VALUE rxml_parser_context_options_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return INT2NUM(ctxt->options);
}

/*
 * call-seq:
 *    context.options = XML::Parser::Options::NOENT |
                        XML::Parser::Options::NOCDATA
 *
 * Provides control over the execution of a parser.  Valid values 
 * are the constants defined on XML::Parser::Options.  Multiple
 * options can be combined by using Bitwise OR (|).
 */
static VALUE rxml_parser_context_options_set(VALUE self, VALUE options)
{
  int result;
  xmlParserCtxtPtr ctxt;
  Check_Type(options, T_FIXNUM);

  Data_Get_Struct(self, xmlParserCtxt, ctxt);
  result = xmlCtxtUseOptions(ctxt, NUM2INT(options));

  return self;
}

/*
 * call-seq:
 *    context.recovery? -> (true|false)
 *
 * Determine whether recovery mode is enabled in this
 * context.
 */
static VALUE rxml_parser_context_recovery_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->recovery)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.recovery = true|false
 *
 * Control whether recovery mode is enabled in this
 * context.
 */
static VALUE rxml_parser_context_recovery_set(VALUE self, VALUE bool)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (TYPE(bool) == T_FALSE)
  {
    ctxt->recovery = 0;
    return (Qfalse);
  }
  else
  {
    ctxt->recovery = 1;
    return (Qtrue);
  }
}

/*
 * call-seq:
 *    context.replace_entities? -> (true|false)
 *
 * Determine whether external entity replacement is enabled in this
 * context.
 */
static VALUE rxml_parser_context_replace_entities_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->replaceEntities)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.replace_entities = true|false
 *
 * Control whether external entity replacement is enabled in this
 * context.
 */
static VALUE rxml_parser_context_replace_entities_set(VALUE self, VALUE bool)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (TYPE(bool) == T_FALSE)
  {
    ctxt->replaceEntities = 0;
    return (Qfalse);
  }
  else
  {
    ctxt->replaceEntities = 1;
    return (Qtrue);
  }
}

/*
 * call-seq:
 *    context.space_depth -> num
 *
 * Obtain the space depth for this context.
 */
static VALUE rxml_parser_context_space_depth_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->spaceNr));
}

/*
 * call-seq:
 *    context.space_depth -> num
 *
 * Obtain the maximum space depth for this context.
 */
static VALUE rxml_parser_context_space_depth_max_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->spaceMax));
}

/*
 * call-seq:
 *    context.subset_external? -> (true|false)
 *
 * Determine whether this context is a subset of an
 * external context.
 */
static VALUE rxml_parser_context_subset_external_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->inSubset == 2)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.subset_internal? -> (true|false)
 *
 * Determine whether this context is a subset of an
 * internal context.
 */
static VALUE rxml_parser_context_subset_internal_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->inSubset == 1)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.subset_internal_name -> "name"
 *
 * Obtain this context's subset name (valid only if
 * either of subset_external? or subset_internal?
 * is true).
 */
static VALUE rxml_parser_context_subset_name_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->intSubName == NULL)
    return (Qnil);
  else
    return (rxml_new_cstr((const char*) ctxt->intSubName, ctxt->encoding));
}

/*
 * call-seq:
 *    context.subset_external_uri -> "uri"
 *
 * Obtain this context's external subset URI. (valid only if
 * either of subset_external? or subset_internal?
 * is true).
 */
static VALUE rxml_parser_context_subset_external_uri_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->extSubURI == NULL)
    return (Qnil);
  else
    return (rxml_new_cstr((const char*) ctxt->extSubURI, ctxt->encoding));
}

/*
 * call-seq:
 *    context.subset_external_system_id -> "system_id"
 *
 * Obtain this context's external subset system identifier.
 * (valid only if either of subset_external? or subset_internal?
 * is true).
 */
static VALUE rxml_parser_context_subset_external_system_id_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->extSubSystem == NULL)
    return (Qnil);
  else
    return (rxml_new_cstr((const char*) ctxt->extSubSystem, ctxt->encoding));
}

/*
 * call-seq:
 *    context.standalone? -> (true|false)
 *
 * Determine whether this is a standalone context.
 */
static VALUE rxml_parser_context_standalone_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->standalone)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.stats? -> (true|false)
 *
 * Determine whether this context maintains statistics.
 */
static VALUE rxml_parser_context_stats_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->record_info)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.valid? -> (true|false)
 *
 * Determine whether this context is valid.
 */
static VALUE rxml_parser_context_valid_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->valid)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.validate? -> (true|false)
 *
 * Determine whether validation is enabled in this context.
 */
static VALUE rxml_parser_context_validate_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->validate)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.version -> "version"
 *
 * Obtain this context's version identifier.
 */
static VALUE rxml_parser_context_version_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->version == NULL)
    return (Qnil);
  else
    return (rxml_new_cstr((const char*) ctxt->version, ctxt->encoding));
}

/*
 * call-seq:
 *    context.well_formed? -> (true|false)
 *
 * Determine whether this context contains well-formed XML.
 */
static VALUE rxml_parser_context_well_formed_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->wellFormed)
    return (Qtrue);
  else
    return (Qfalse);
}

void rxml_init_parser_context(void)
{
  IO_ATTR = ID2SYM(rb_intern("@io"));

  cXMLParserContext = rb_define_class_under(cXMLParser, "Context", rb_cObject);
  rb_define_alloc_func(cXMLParserContext, rxml_parser_context_alloc);

  rb_define_singleton_method(cXMLParserContext, "document", rxml_parser_context_document, 1);
  rb_define_singleton_method(cXMLParserContext, "file", rxml_parser_context_file, 1);
  rb_define_singleton_method(cXMLParserContext, "io", rxml_parser_context_io, 1);
  rb_define_singleton_method(cXMLParserContext, "string", rxml_parser_context_string, 1);

  rb_define_method(cXMLParserContext, "base_uri", rxml_parser_context_base_uri_get, 0);
  rb_define_method(cXMLParserContext, "base_uri=", rxml_parser_context_base_uri_set, 1);
  rb_define_method(cXMLParserContext, "close", rxml_parser_context_close, 0);
  rb_define_method(cXMLParserContext, "data_directory", rxml_parser_context_data_directory_get, 0);
  rb_define_method(cXMLParserContext, "depth", rxml_parser_context_depth_get, 0);
  rb_define_method(cXMLParserContext, "disable_cdata?", rxml_parser_context_disable_cdata_q, 0);
  rb_define_method(cXMLParserContext, "disable_cdata=", rxml_parser_context_disable_cdata_set, 1);
  rb_define_method(cXMLParserContext, "disable_sax?", rxml_parser_context_disable_sax_q, 0);
  rb_define_method(cXMLParserContext, "docbook?", rxml_parser_context_docbook_q, 0);
  rb_define_method(cXMLParserContext, "encoding", rxml_parser_context_encoding_get, 0);
  rb_define_method(cXMLParserContext, "encoding=", rxml_parser_context_encoding_set, 1);
  rb_define_method(cXMLParserContext, "errno", rxml_parser_context_errno_get, 0);
  rb_define_method(cXMLParserContext, "html?", rxml_parser_context_html_q, 0);
  rb_define_method(cXMLParserContext, "io_max_num_streams", rxml_parser_context_io_max_num_streams_get, 0);
  rb_define_method(cXMLParserContext, "io_num_streams", rxml_parser_context_io_num_streams_get, 0);
  rb_define_method(cXMLParserContext, "keep_blanks?", rxml_parser_context_keep_blanks_q, 0);
  rb_define_method(cXMLParserContext, "name_node", rxml_parser_context_name_node_get, 0);
  rb_define_method(cXMLParserContext, "name_depth", rxml_parser_context_name_depth_get, 0);
  rb_define_method(cXMLParserContext, "name_depth_max", rxml_parser_context_name_depth_max_get, 0);
  rb_define_method(cXMLParserContext, "name_tab", rxml_parser_context_name_tab_get, 0);
  rb_define_method(cXMLParserContext, "node", rxml_parser_context_node_get, 0);
  rb_define_method(cXMLParserContext, "node_depth", rxml_parser_context_node_depth_get, 0);
  rb_define_method(cXMLParserContext, "node_depth_max", rxml_parser_context_node_depth_max_get, 0);
  rb_define_method(cXMLParserContext, "num_chars", rxml_parser_context_num_chars_get, 0);
  rb_define_method(cXMLParserContext, "options", rxml_parser_context_options_get, 0);
  rb_define_method(cXMLParserContext, "options=", rxml_parser_context_options_set, 1);
  rb_define_method(cXMLParserContext, "recovery?", rxml_parser_context_recovery_q, 0);
  rb_define_method(cXMLParserContext, "recovery=", rxml_parser_context_recovery_set, 1);
  rb_define_method(cXMLParserContext, "replace_entities?", rxml_parser_context_replace_entities_q, 0);
  rb_define_method(cXMLParserContext, "replace_entities=", rxml_parser_context_replace_entities_set, 1);
  rb_define_method(cXMLParserContext, "space_depth", rxml_parser_context_space_depth_get, 0);
  rb_define_method(cXMLParserContext, "space_depth_max", rxml_parser_context_space_depth_max_get, 0);
  rb_define_method(cXMLParserContext, "subset_external?", rxml_parser_context_subset_external_q, 0);
  rb_define_method(cXMLParserContext, "subset_external_system_id", rxml_parser_context_subset_external_system_id_get, 0);
  rb_define_method(cXMLParserContext, "subset_external_uri", rxml_parser_context_subset_external_uri_get, 0);
  rb_define_method(cXMLParserContext, "subset_internal?", rxml_parser_context_subset_internal_q, 0);
  rb_define_method(cXMLParserContext, "subset_internal_name", rxml_parser_context_subset_name_get, 0);
  rb_define_method(cXMLParserContext, "stats?", rxml_parser_context_stats_q, 0);
  rb_define_method(cXMLParserContext, "standalone?", rxml_parser_context_standalone_q, 0);
  rb_define_method(cXMLParserContext, "valid", rxml_parser_context_valid_q, 0);
  rb_define_method(cXMLParserContext, "validate?", rxml_parser_context_validate_q, 0);
  rb_define_method(cXMLParserContext, "version", rxml_parser_context_version_get, 0);
  rb_define_method(cXMLParserContext, "well_formed?", rxml_parser_context_well_formed_q, 0);
}
