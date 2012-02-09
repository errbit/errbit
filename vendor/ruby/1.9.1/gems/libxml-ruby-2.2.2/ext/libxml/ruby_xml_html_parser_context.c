/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"
#include "ruby_xml_html_parser_context.h"


/*
 * Document-class: LibXML::XML::HTMLParser::Context
 *
 * The XML::HTMLParser::Context class provides in-depth control over how
 * a document is parsed.
 */

VALUE cXMLHtmlParserContext;
static ID IO_ATTR;

/* OS X 10.5 ships with libxml2 version 2.6.16 which does not expose the
   htmlNewParserCtxt (or htmlInitParserCtxt which it uses) method.  htmlNewParserCtxt
   wasn't added to the libxml2 header files until 2.6.27.  So the next two 
   methods are simply copied from a newer version of libxml2 (2.7.2). */
#if LIBXML_VERSION < 20627
#define XML_CTXT_FINISH_DTD_0 0xabcd1234
static int htmlInitParserCtxt(htmlParserCtxtPtr ctxt)
{
  htmlSAXHandler *sax;
  if (ctxt == NULL) return(-1);
  
  memset(ctxt, 0, sizeof(htmlParserCtxt));
  ctxt->dict = xmlDictCreate();
  if (ctxt->dict == NULL) {
    rb_raise(rb_eNoMemError, "htmlInitParserCtxt: out of memory\n");
    return(-1);
  }
  sax = (htmlSAXHandler *) xmlMalloc(sizeof(htmlSAXHandler));
  if (sax == NULL) {
    rb_raise(rb_eNoMemError, "htmlInitParserCtxt: out of memory\n");
    return(-1);
  }
  else
    memset(sax, 0, sizeof(htmlSAXHandler));

  ctxt->inputTab = (htmlParserInputPtr *) xmlMalloc(5 * sizeof(htmlParserInputPtr));
  if (ctxt->inputTab == NULL) {
    rb_raise(rb_eNoMemError, "htmlInitParserCtxt: out of memory\n");
    ctxt->inputNr = 0;
    ctxt->inputMax = 0;
    ctxt->input = NULL;
    return(-1);
  }
  ctxt->inputNr = 0;
  ctxt->inputMax = 5;
  ctxt->input = NULL;
  ctxt->version = NULL;
  ctxt->encoding = NULL;
  ctxt->standalone = -1;
  ctxt->instate = XML_PARSER_START;

  ctxt->nodeTab = (htmlNodePtr *) xmlMalloc(10 * sizeof(htmlNodePtr));
  if (ctxt->nodeTab == NULL) {
    rb_raise(rb_eNoMemError, "htmlInitParserCtxt: out of memory\n");
    ctxt->nodeNr = 0;
    ctxt->nodeMax = 0;
    ctxt->node = NULL;
    ctxt->inputNr = 0;
    ctxt->inputMax = 0;
    ctxt->input = NULL;
    return(-1);
  }
  ctxt->nodeNr = 0;
  ctxt->nodeMax = 10;
  ctxt->node = NULL;

  ctxt->nameTab = (const xmlChar **) xmlMalloc(10 * sizeof(xmlChar *));
  if (ctxt->nameTab == NULL) {
    rb_raise(rb_eNoMemError, "htmlInitParserCtxt: out of memory\n");
    ctxt->nameNr = 0;
    ctxt->nameMax = 10;
    ctxt->name = NULL;
    ctxt->nodeNr = 0;
    ctxt->nodeMax = 0;
    ctxt->node = NULL;
    ctxt->inputNr = 0;
    ctxt->inputMax = 0;
    ctxt->input = NULL;
    return(-1);
  }
  ctxt->nameNr = 0;
  ctxt->nameMax = 10;
  ctxt->name = NULL;
  	
  if (sax == NULL) ctxt->sax = (xmlSAXHandlerPtr) &htmlDefaultSAXHandler;
  else {
    ctxt->sax = sax;
    memcpy(sax, &htmlDefaultSAXHandler, sizeof(xmlSAXHandlerV1));
  }
  ctxt->userData = ctxt;
  ctxt->myDoc = NULL;
  ctxt->wellFormed = 1;
  ctxt->replaceEntities = 0;
  ctxt->linenumbers = xmlLineNumbersDefaultValue;
  ctxt->html = 1;
  ctxt->vctxt.finishDtd = XML_CTXT_FINISH_DTD_0;
  ctxt->vctxt.userData = ctxt;
  ctxt->vctxt.error = xmlParserValidityError;
  ctxt->vctxt.warning = xmlParserValidityWarning;
  ctxt->record_info = 0;
  ctxt->validate = 0;
  ctxt->nbChars = 0;
  ctxt->checkIndex = 0;
  ctxt->catalogs = NULL;
  xmlInitNodeInfoSeq(&ctxt->node_seq);
  return(0);
}

static htmlParserCtxtPtr htmlNewParserCtxt(void)
{
  xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) xmlMalloc(sizeof(xmlParserCtxt));
  if (ctxt == NULL) {
    rb_raise(rb_eNoMemError, "NewParserCtxt: out of memory\n");
    return(NULL);
  }
  memset(ctxt, 0, sizeof(xmlParserCtxt));
  if (htmlInitParserCtxt(ctxt) < 0) {
    htmlFreeParserCtxt(ctxt);
   return(NULL);
  }
  return(ctxt);
}
#endif

static void rxml_html_parser_context_free(htmlParserCtxtPtr ctxt)
{
  htmlFreeParserCtxt(ctxt);
}

static VALUE rxml_html_parser_context_wrap(htmlParserCtxtPtr ctxt)
{
  return Data_Wrap_Struct(cXMLHtmlParserContext, NULL, rxml_html_parser_context_free, ctxt);
}

/* call-seq:
 *    XML::HTMLParser::Context.file(file) -> XML::HTMLParser::Context
 *
 * Creates a new parser context based on the specified file or uri.
 *
 * Parameters:
 *
 *  file - A filename or uri.
*/
static VALUE rxml_html_parser_context_file(VALUE klass, VALUE file)
{
  htmlParserCtxtPtr ctxt = htmlCreateFileParserCtxt(StringValuePtr(file), NULL);
  if (!ctxt)
    rxml_raise(&xmlLastError);

  /* This is annoying, but xmlInitParserCtxt (called indirectly above) and 
     xmlCtxtUseOptionsInternal (called below) initialize slightly different
     context options, in particular XML_PARSE_NODICT which xmlInitParserCtxt
     sets to 0 and xmlCtxtUseOptionsInternal sets to 1.  So we have to call both. */
  htmlCtxtUseOptions(ctxt, rxml_libxml_default_options());

  return rxml_html_parser_context_wrap(ctxt);
}

/* call-seq:
 *    XML::HTMLParser::Context.io(io) -> XML::HTMLParser::Context
 *
 * Creates a new parser context based on the specified io object.
 *
 * Parameters:
 *
 *  io - A ruby IO object.
*/
static VALUE rxml_html_parser_context_io(VALUE klass, VALUE io)
{
  VALUE result;
  htmlParserCtxtPtr ctxt;
  xmlParserInputBufferPtr input;
  xmlParserInputPtr stream;

  if (NIL_P(io))
    rb_raise(rb_eTypeError, "Must pass in an IO object");

  input = xmlParserInputBufferCreateIO((xmlInputReadCallback) rxml_read_callback, NULL,
                                     (void*)io, XML_CHAR_ENCODING_NONE);

  ctxt = htmlNewParserCtxt();
  if (!ctxt)
  {
    xmlFreeParserInputBuffer(input);
    rxml_raise(&xmlLastError);
  }

  /* This is annoying, but xmlInitParserCtxt (called indirectly above) and 
     xmlCtxtUseOptionsInternal (called below) initialize slightly different
     context options, in particular XML_PARSE_NODICT which xmlInitParserCtxt
     sets to 0 and xmlCtxtUseOptionsInternal sets to 1.  So we have to call both. */
  htmlCtxtUseOptions(ctxt, rxml_libxml_default_options());

  stream = xmlNewIOInputStream(ctxt, input, XML_CHAR_ENCODING_NONE);

  if (!stream)
  {
    xmlFreeParserInputBuffer(input);
    xmlFreeParserCtxt(ctxt);
    rxml_raise(&xmlLastError);
  }
  inputPush(ctxt, stream);
  result = rxml_html_parser_context_wrap(ctxt);

  /* Attach io object to parser so it won't get freed.*/
  rb_ivar_set(result, IO_ATTR, io);

  return result;
}

/* call-seq:
 *    XML::HTMLParser::Context.string(string) -> XML::HTMLParser::Context
 *
 * Creates a new parser context based on the specified string.
 *
 * Parameters:
 *
 *  string - A string that contains the data to parse.
*/
static VALUE rxml_html_parser_context_string(VALUE klass, VALUE string)
{
  htmlParserCtxtPtr ctxt;
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
  htmlCtxtUseOptions(ctxt, rxml_libxml_default_options());

  htmlDefaultSAXHandlerInit();
  if (ctxt->sax != NULL)
    memcpy(ctxt->sax, &htmlDefaultSAXHandler, sizeof(xmlSAXHandlerV1));
  
  return rxml_html_parser_context_wrap(ctxt);
}

/*
 * call-seq:
 *    context.close -> nil
 *
 * Closes the underlying input streams.  This is useful when parsing a large amount of
 * files and you want to close the files without relying on Ruby's garbage collector
 * to run.
 */
static VALUE rxml_html_parser_context_close(VALUE self)
{
  htmlParserCtxtPtr ctxt;
  xmlParserInputPtr xinput;
  Data_Get_Struct(self, htmlParserCtxt, ctxt);

  while ((xinput = inputPop(ctxt)) != NULL)
  {
	 xmlFreeInputStream(xinput);
  }
  return Qnil;
}

/*
 * call-seq:
 *    context.disable_cdata = (true|false)
 *
 * Control whether the CDATA nodes will be created in this context.
 */
static VALUE rxml_html_parser_context_disable_cdata_set(VALUE self, VALUE bool)
{
  htmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, htmlParserCtxt, ctxt);

  if (ctxt->sax == NULL)
    rb_raise(rb_eRuntimeError, "Sax handler is not yet set");

  /* LibXML controls this internally with the default SAX handler. */ 
  if (bool)
    ctxt->sax->cdataBlock = NULL;
  else
    ctxt->sax->cdataBlock = htmlDefaultSAXHandler.cdataBlock;

  return bool;
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
static VALUE rxml_html_parser_context_options_set(VALUE self, VALUE options)
{
  int result;
  int xml_options = NUM2INT(options);
  htmlParserCtxtPtr ctxt;
  Check_Type(options, T_FIXNUM);

  Data_Get_Struct(self, htmlParserCtxt, ctxt);
  result = htmlCtxtUseOptions(ctxt, xml_options);

#if LIBXML_VERSION >= 20707
  /* Big hack here, but htmlCtxtUseOptions doens't support HTML_PARSE_NOIMPLIED.
     So do it ourselves. There must be a better way??? */
  if (xml_options & HTML_PARSE_NOIMPLIED) 
  {
	  ctxt->options |= HTML_PARSE_NOIMPLIED;
  }
#endif

  return self;
}

void rxml_init_html_parser_context(void)
{
  IO_ATTR = ID2SYM(rb_intern("@io"));
  cXMLHtmlParserContext = rb_define_class_under(cXMLHtmlParser, "Context", cXMLParserContext);

  rb_define_singleton_method(cXMLHtmlParserContext, "file", rxml_html_parser_context_file, 1);
  rb_define_singleton_method(cXMLHtmlParserContext, "io", rxml_html_parser_context_io, 1);
  rb_define_singleton_method(cXMLHtmlParserContext, "string", rxml_html_parser_context_string, 1);
  rb_define_method(cXMLHtmlParserContext, "close", rxml_html_parser_context_close, 0);
  rb_define_method(cXMLHtmlParserContext, "disable_cdata=", rxml_html_parser_context_disable_cdata_set, 1);
  rb_define_method(cXMLHtmlParserContext, "options=", rxml_html_parser_context_options_set, 1);
}
