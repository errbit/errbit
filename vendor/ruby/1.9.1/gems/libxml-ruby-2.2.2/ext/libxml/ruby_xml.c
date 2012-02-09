#include "ruby_libxml.h"
#include "ruby_xml.h"

VALUE mXML;

/*
 * call-seq:
 * 		XML.catalog_dump -> true
 *
 * Dump all the global catalog content stdout.
 */
static VALUE rxml_catalog_dump(VALUE self)
{
  xmlCatalogDump(stdout);
  return (Qtrue);
}

/*
 * call-seq:
 * 		XML.catalog_remove(catalog) -> true
 *
 * Remove the specified resource catalog.
 */
static VALUE rxml_catalog_remove(VALUE self, VALUE cat)
{
  Check_Type(cat, T_STRING);
  xmlCatalogRemove((xmlChar *) StringValuePtr(cat));
  return (Qtrue);
}

/*
 * call-seq:
 * 		XML.check_lib_versions -> true
 *
 * Check LIBXML version matches version the bindings
 * were compiled to. Throws an exception if not.
 */
static VALUE rxml_check_lib_versions(VALUE klass)
{
  xmlCheckVersion(LIBXML_VERSION);
  return (Qtrue);
}

/*
 * call-seq:
 * 		XML.enabled_automata? -> (true|false)
 *
 * Determine whether libxml regexp automata support is enabled.
 */
static VALUE rxml_enabled_automata_q(VALUE klass)
{
#ifdef LIBXML_AUTOMATA_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_c14n? -> (true|false)
 *
 * Determine whether libxml 'canonical XML' support is enabled.
 * See "Canonical XML" (http://www.w3.org/TR/xml-c14n)
 */
static VALUE rxml_enabled_c14n_q(VALUE klass)
{
#ifdef LIBXML_C14N_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_catalog? -> (true|false)
 *
 * Determine whether libxml resource catalog support is enabled.
 */
static VALUE rxml_enabled_catalog_q(VALUE klass)
{
#ifdef LIBXML_CATALOG_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_debug? -> (true|false)
 *
 * Determine whether libxml debugging support is enabled.
 */
static VALUE rxml_enabled_debug_q(VALUE klass)
{
#ifdef LIBXML_DEBUG_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_docbook? -> (true|false)
 *
 * Determine whether libxml docbook support is enabled.
 */
static VALUE rxml_enabled_docbook_q(VALUE klass)
{
#ifdef LIBXML_DOCB_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_ftp? -> (true|false)
 *
 * Determine whether libxml ftp client support is enabled.
 */
static VALUE rxml_enabled_ftp_q(VALUE klass)
{
#ifdef LIBXML_FTP_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_http? -> (true|false)
 *
 * Determine whether libxml http client support is enabled.
 */
static VALUE rxml_enabled_http_q(VALUE klass)
{
#ifdef LIBXML_HTTP_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_html? -> (true|false)
 *
 * Determine whether libxml html support is enabled.
 */
static VALUE rxml_enabled_html_q(VALUE klass)
{
#ifdef LIBXML_HTML_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_iconv? -> (true|false)
 *
 * Determine whether libxml iconv support is enabled.
 */
static VALUE rxml_enabled_iconv_q(VALUE klass)
{
#ifdef LIBXML_ICONV_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_memory_debug? -> (true|false)
 *
 * Determine whether libxml memory location debugging support
 * is enabled.
 */
static VALUE rxml_enabled_memory_debug_location_q(VALUE klass)
{
#ifdef DEBUG_MEMORY_LOCATION
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_regexp? -> (true|false)
 *
 * Determine whether libxml regular expression support is enabled.
 */
static VALUE rxml_enabled_regexp_q(VALUE klass)
{
#ifdef LIBXML_REGEXP_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_schemas? -> (true|false)
 *
 * Determine whether libxml schema support is enabled.
 */
static VALUE rxml_enabled_schemas_q(VALUE klass)
{
#ifdef LIBXML_SCHEMAS_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_thread? -> (true|false)
 *
 * Determine whether thread-safe semantics support for libxml is enabled and
 * is used by this ruby extension.  Threading support in libxml uses pthread
 * on Unix-like systems and Win32 threads on Windows.
 */
static VALUE rxml_enabled_thread_q(VALUE klass)
{
  /* This won't be defined unless this code is compiled with _REENTRANT or __MT__
   * defined or the compiler is in C99 mode.
   *
   * Note the relevant portion libxml/xmlversion.h on a thread-enabled build:
   *
   *    #if defined(_REENTRANT) || defined(__MT__) || \
   *        (defined(_POSIX_C_SOURCE) && (_POSIX_C_SOURCE - 0 >= 199506L))
   *        #define LIBXML_THREAD_ENABLED
   *    #endif
   *
   */
#ifdef LIBXML_THREAD_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_unicode? -> (true|false)
 *
 * Determine whether libxml unicode support is enabled.
 */
static VALUE rxml_enabled_unicode_q(VALUE klass)
{
#ifdef LIBXML_UNICODE_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_xinclude? -> (true|false)
 *
 * Determine whether libxml xinclude support is enabled.
 */
static VALUE rxml_enabled_xinclude_q(VALUE klass)
{
#ifdef LIBXML_XINCLUDE_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_xpath? -> (true|false)
 *
 * Determine whether libxml xpath support is enabled.
 */
static VALUE rxml_enabled_xpath_q(VALUE klass)
{
#ifdef LIBXML_XPATH_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_xpointer? -> (true|false)
 *
 * Determine whether libxml xpointer support is enabled.
 */
static VALUE rxml_enabled_xpointer_q(VALUE klass)
{
#ifdef LIBXML_XPTR_ENABLED
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 * 		XML.enabled_zlib? -> (true|false)
 *
 * Determine whether libxml zlib support is enabled.
 */
static VALUE rxml_enabled_zlib_q(VALUE klass)
{
#ifdef HAVE_ZLIB_H
  return(Qtrue);
#else
  return (Qfalse);
#endif
}

/*
 * call-seq:
 *    XML.debug_entities -> (true|false)
 *
 * Determine whether included-entity debugging is enabled.
 * (Requires Libxml to be compiled with debugging support)
 */
static VALUE rxml_debug_entities_get(VALUE klass)
{
#ifdef LIBXML_DEBUG_ENABLED
  if (xmlParserDebugEntities)
  return(Qtrue);
  else
  return(Qfalse);
#else
  rb_warn("libxml was compiled with debugging turned off");
  return (Qfalse);
#endif
}

/*
 * call-seq:
 *    XML.debug_entities = true|false
 *
 * Enable or disable included-entity debugging.
 * (Requires Libxml to be compiled with debugging support)
 */
static VALUE rxml_debug_entities_set(VALUE klass, VALUE bool)
{
#ifdef LIBXML_DEBUG_ENABLED
  if (TYPE(bool) == T_FALSE)
  {
    xmlParserDebugEntities = 0;
    return(Qfalse);
  }
  else
  {
    xmlParserDebugEntities = 1;
    return(Qtrue);
  }
#else
  rb_warn("libxml was compiled with debugging turned off");
#endif
}

/*
 * call-seq:
 *    XML.default_keep_blanks -> (true|false)
 *
 * Determine whether parsers retain whitespace by default.
 */
static VALUE rxml_default_keep_blanks_get(VALUE klass)
{
  if (xmlKeepBlanksDefaultValue)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    XML.default_keep_blanks = true|false
 *
 * Controls whether parsers retain whitespace by default.
 */
static VALUE rxml_default_keep_blanks_set(VALUE klass, VALUE bool)
{
  if (TYPE(bool) == T_FALSE)
  {
    xmlKeepBlanksDefaultValue = 0;
    return (Qfalse);
  }
  else if (TYPE(bool) == T_TRUE)
  {
    xmlKeepBlanksDefaultValue = 1;
    return (Qtrue);
  }
  else
  {
    rb_raise(rb_eArgError, "Invalid argument, must be a boolean");
  }
}

/*
 * call-seq:
 *    XML.default_load_external_dtd -> (true|false)
 *
 * Determine whether parsers load external DTDs by default.
 */
static VALUE rxml_default_load_external_dtd_get(VALUE klass)
{
  if (xmlLoadExtDtdDefaultValue)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    XML.default_load_external_dtd = true|false
 *
 * Controls whether parsers load external DTDs by default.
 */
static VALUE rxml_default_load_external_dtd_set(VALUE klass, VALUE bool)
{
  if (bool == Qfalse)
  {
    xmlLoadExtDtdDefaultValue = 0;
    return (Qfalse);
  }
  else
  {
    xmlLoadExtDtdDefaultValue = 1;
    return (Qtrue);
  }
}

/*
 * call-seq:
 *    XML.default_line_numbers -> (true|false)
 *
 * Determine whether parsers retain line-numbers by default.
 */
static VALUE rxml_default_line_numbers_get(VALUE klass)
{
  if (xmlLineNumbersDefaultValue)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    XML.default_line_numbers = true|false
 *
 * Controls whether parsers retain line-numbers by default.
 */
static VALUE rxml_default_line_numbers_set(VALUE klass, VALUE bool)
{
  if (TYPE(bool) == T_FALSE)
  {
    xmlLineNumbersDefault(0);
    return (Qfalse);
  }
  else
  {
    xmlLineNumbersDefault(1);
    return (Qtrue);
  }
}

int rxml_libxml_default_options()
{
  int options = 0;

  if (xmlLoadExtDtdDefaultValue)
    options |= XML_PARSE_DTDLOAD;

  if (xmlDoValidityCheckingDefaultValue)
    options |= XML_PARSE_DTDVALID;

  if (!xmlKeepBlanksDefaultValue)
    options |= XML_PARSE_NOBLANKS;

  if (xmlSubstituteEntitiesDefaultValue)
    options |= XML_PARSE_NOENT;

  if (!xmlGetWarningsDefaultValue)
    options |= XML_PARSE_NOWARNING;

  if (xmlPedanticParserDefaultValue)
    options |= XML_PARSE_PEDANTIC;
  
  return options;
}

/*
 * call-seq:
 *    XML.default_options -> int
 *
 * Returns an integer that summarize libxml2's default options.
 */
static VALUE rxml_default_options_get(VALUE klass)
{
  int options = rxml_libxml_default_options();
  return INT2NUM(options);
}

/*
 * call-seq:
 *    XML.default_pedantic_parser -> (true|false)
 *
 * Determine whether parsers are pedantic by default.
 */
static VALUE rxml_default_pedantic_parser_get(VALUE klass)
{
  if (xmlPedanticParserDefaultValue)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    XML.default_pedantic_parser = true|false
 *
 * Controls whether parsers are pedantic by default.
 */
static VALUE rxml_default_pedantic_parser_set(VALUE klass, VALUE bool)
{
  if (TYPE(bool) == T_FALSE)
  {
    xmlPedanticParserDefault(0);
    return (Qfalse);
  }
  else
  {
    xmlPedanticParserDefault(1);
    return (Qtrue);
  }
}

/*
 * call-seq:
 *    XML.default_substitute_entities -> (true|false)
 *
 * Determine whether parsers perform inline entity substitution
 * (for external entities) by default.
 */
static VALUE rxml_default_substitute_entities_get(VALUE klass)
{
  if (xmlSubstituteEntitiesDefaultValue)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    XML.default_substitute_entities = true|false
 *
 * Controls whether parsers perform inline entity substitution
 * (for external entities) by default.
 */
static VALUE rxml_default_substitute_entities_set(VALUE klass, VALUE bool)
{
  if (bool == Qfalse)
  {
    xmlSubstituteEntitiesDefault(0);
    return (Qfalse);
  }
  else
  {
    xmlSubstituteEntitiesDefault(1);
    return (Qtrue);
  }
}

/*
 * call-seq:
 *    XML.default_tree_indent_string -> "string"
 *
 * Obtain the default string used by parsers to indent the XML tree
 * for output.
 */
static VALUE rxml_default_tree_indent_string_get(VALUE klass)
{
  if (xmlTreeIndentString == NULL)
    return (Qnil);
  else
    return (rb_str_new2(xmlTreeIndentString));
}

/*
 * call-seq:
 *    XML.default_tree_indent_string = "string"
 *
 * Set the default string used by parsers to indent the XML tree
 * for output.
 */
static VALUE rxml_default_tree_indent_string_set(VALUE klass, VALUE string)
{
  Check_Type(string, T_STRING);
  xmlTreeIndentString = xmlStrdup((xmlChar *)StringValuePtr(string));
  return (string);
}

/*
 * call-seq:
 *    XML.default_validity_checking -> (true|false)
 *
 * Determine whether parsers perform XML validation by default.
 */
static VALUE rxml_default_validity_checking_get(VALUE klass)
{
  if (xmlDoValidityCheckingDefaultValue)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    XML.default_validity_checking = true|false
 *
 * Controls whether parsers perform XML validation by default.
 */
static VALUE rxml_default_validity_checking_set(VALUE klass, VALUE bool)
{
  if (TYPE(bool) == T_FALSE)
  {
    xmlDoValidityCheckingDefaultValue = 0;
    return (Qfalse);
  }
  else
  {
    xmlDoValidityCheckingDefaultValue = 1;
    return (Qtrue);
  }
}

/*
 * call-seq:
 *    XML.default_warnings -> (true|false)
 *
 * Determine whether parsers output warnings by default.
 */
static VALUE rxml_default_warnings_get(VALUE klass)
{
  if (xmlGetWarningsDefaultValue)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    XML.default_warnings = true|false
 *
 * Controls whether parsers output warnings by default.
 */
static VALUE rxml_default_warnings_set(VALUE klass, VALUE bool)
{
  if (TYPE(bool) == T_FALSE)
  {
    xmlGetWarningsDefaultValue = 0;
    return (Qfalse);
  }
  else
  {
    xmlGetWarningsDefaultValue = 1;
    return (Qtrue);
  }
}

/*
 * call-seq:
 *    XML.default_compression -> (true|false)
 *
 * Determine whether parsers use Zlib compression by default
 * (requires libxml to be compiled with Zlib support).
 */
static VALUE rxml_default_compression_get(VALUE klass)
{
#ifdef HAVE_ZLIB_H
  return(INT2FIX(xmlGetCompressMode()));
#else
  rb_warn("libxml was compiled without zlib support");
  return (Qfalse);
#endif
}

/*
 * call-seq:
 *    XML.default_compression = true|false
 *
 * Controls whether parsers use Zlib compression by default
 * (requires libxml to be compiled with Zlib support).
 */
static VALUE rxml_default_compression_set(VALUE klass, VALUE num)
{
#ifdef HAVE_ZLIB_H
  Check_Type(num, T_FIXNUM);
  xmlSetCompressMode(FIX2INT(num));
  return(num);
#else
  rb_warn("libxml was compiled without zlib support");
  return (Qfalse);
#endif
}

/*
 * call-seq:
 *    XML.features -> ["feature", ..., "feature"]
 *
 * Obtains an array of strings representing features supported
 * (and enabled) by the installed libxml.
 */
static VALUE rxml_features(VALUE klass)
{
  VALUE arr, str;
  int i, len = MAX_LIBXML_FEATURES_LEN;
  char **list = NULL;

  list = ALLOC_N(char *,MAX_LIBXML_FEATURES_LEN);
  MEMZERO(list, char *, MAX_LIBXML_FEATURES_LEN);

  arr = rb_ary_new();
  if (xmlGetFeaturesList(&len, (const char **) list) == -1)
    return Qnil;

  for (i = 0; i < len; i++)
  {
    str = rb_str_new2((const char *) list[i]);
    rb_gc_unregister_address(&str);
    rb_ary_push(arr, str);
  }

  if (len == MAX_LIBXML_FEATURES_LEN)
    rb_warn(
        "Please contact libxml-devel@rubyforge.org and ask to have the \"MAX_LIBXML_FEATURES_LEN increased\" because you could possibly be seeing an incomplete list");

  ruby_xfree(list);
  return (arr);
}

/*
 * call-seq:
 *    XML.indent_tree_output -> (true|false)
 *
 * Determines whether XML output will be indented
 * (using the string supplied to +default_indent_tree_string+)
 */
static VALUE rxml_indent_tree_output_get(VALUE klass)
{
  if (xmlIndentTreeOutput)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    XML.indent_tree_output = true|false
 *
 * Controls whether XML output will be indented
 * (using the string supplied to +default_indent_tree_string+)
 */
static VALUE rxml_indent_tree_output_set(VALUE klass, VALUE bool)
{
  if (TYPE(bool) == T_TRUE)
  {
    xmlIndentTreeOutput = 1;
    return (Qtrue);
  }
  else if (TYPE(bool) == T_FALSE)
  {
    xmlIndentTreeOutput = 0;
    return (Qfalse);
  }
  else
  {
    rb_raise(rb_eArgError, "Invalid argument, must be boolean");
  }
}

/*
 * call-seq:
 *    XML.memory_dump -> (true|false)
 *
 * Perform a parser memory dump (requires memory debugging
 * support in libxml).
 */
static VALUE rxml_memory_dump(VALUE self)
{
#ifdef DEBUG_MEMORY_LOCATION
  xmlMemoryDump();
  return(Qtrue);
#else
  rb_warn("libxml was compiled without memory debugging support");
  return (Qfalse);
#endif
}

/*
 * call-seq:
 *    XML.memory_used -> num_bytes
 *
 * Perform a parser memory dump (requires memory debugging
 * support in libxml).
 */
static VALUE rxml_memory_used(VALUE self)
{
#ifdef DEBUG_MEMORY_LOCATION
  return(INT2NUM(xmlMemUsed()));
#else
  rb_warn("libxml was compiled without memory debugging support");
  return (Qfalse);
#endif
}

/* The libxml gem provides Ruby language bindings for GNOME's Libxml2
 * XML toolkit. Refer to the README file to get started
 * and the LICENSE file for copyright and distribution information.
*/

void rxml_init_xml(void)
{
  mXML = rb_define_module_under(mLibXML, "XML");

  /* Constants */
  rb_define_const(mXML, "LIBXML_VERSION", rb_str_new2(LIBXML_DOTTED_VERSION));
  rb_define_const(mXML, "VERSION", rb_str_new2(RUBY_LIBXML_VERSION));
  rb_define_const(mXML, "VERNUM", INT2NUM(RUBY_LIBXML_VERNUM));
  rb_define_const(mXML, "XML_NAMESPACE", rb_str_new2((const char*) XML_XML_NAMESPACE));

  rb_define_module_function(mXML, "enabled_automata?", rxml_enabled_automata_q, 0);
  rb_define_module_function(mXML, "enabled_c14n?", rxml_enabled_c14n_q, 0);
  rb_define_module_function(mXML, "enabled_catalog?", rxml_enabled_catalog_q, 0);
  rb_define_module_function(mXML, "enabled_debug?", rxml_enabled_debug_q, 0);
  rb_define_module_function(mXML, "enabled_docbook?", rxml_enabled_docbook_q, 0);
  rb_define_module_function(mXML, "enabled_ftp?", rxml_enabled_ftp_q, 0);
  rb_define_module_function(mXML, "enabled_http?", rxml_enabled_http_q, 0);
  rb_define_module_function(mXML, "enabled_html?", rxml_enabled_html_q, 0);
  rb_define_module_function(mXML, "enabled_iconv?", rxml_enabled_iconv_q, 0);
  rb_define_module_function(mXML, "enabled_memory_debug?", rxml_enabled_memory_debug_location_q, 0);
  rb_define_module_function(mXML, "enabled_regexp?", rxml_enabled_regexp_q, 0);
  rb_define_module_function(mXML, "enabled_schemas?", rxml_enabled_schemas_q, 0);
  rb_define_module_function(mXML, "enabled_thread?", rxml_enabled_thread_q, 0);
  rb_define_module_function(mXML, "enabled_unicode?", rxml_enabled_unicode_q, 0);
  rb_define_module_function(mXML, "enabled_xinclude?", rxml_enabled_xinclude_q, 0);
  rb_define_module_function(mXML, "enabled_xpath?", rxml_enabled_xpath_q, 0);
  rb_define_module_function(mXML, "enabled_xpointer?", rxml_enabled_xpointer_q, 0);
  rb_define_module_function(mXML, "enabled_zlib?", rxml_enabled_zlib_q, 0);

  rb_define_module_function(mXML, "catalog_dump", rxml_catalog_dump, 0);
  rb_define_module_function(mXML, "catalog_remove", rxml_catalog_remove, 1);
  rb_define_module_function(mXML, "check_lib_versions", rxml_check_lib_versions, 0);
  rb_define_module_function(mXML, "debug_entities", rxml_debug_entities_get, 0);
  rb_define_module_function(mXML, "debug_entities=", rxml_debug_entities_set, 1);
  rb_define_module_function(mXML, "default_compression", rxml_default_compression_get, 0);
  rb_define_module_function(mXML, "default_compression=", rxml_default_compression_set, 1);
  rb_define_module_function(mXML, "default_keep_blanks", rxml_default_keep_blanks_get, 0);
  rb_define_module_function(mXML, "default_keep_blanks=", rxml_default_keep_blanks_set, 1);
  rb_define_module_function(mXML, "default_load_external_dtd", rxml_default_load_external_dtd_get, 0);
  rb_define_module_function(mXML, "default_load_external_dtd=", rxml_default_load_external_dtd_set, 1);
  rb_define_module_function(mXML, "default_line_numbers", rxml_default_line_numbers_get, 0);
  rb_define_module_function(mXML, "default_line_numbers=", rxml_default_line_numbers_set, 1);
  rb_define_module_function(mXML, "default_options", rxml_default_options_get, 0);
  rb_define_module_function(mXML, "default_pedantic_parser", rxml_default_pedantic_parser_get, 0);
  rb_define_module_function(mXML, "default_pedantic_parser=", rxml_default_pedantic_parser_set, 1);
  rb_define_module_function(mXML, "default_substitute_entities", rxml_default_substitute_entities_get, 0);
  rb_define_module_function(mXML, "default_substitute_entities=", rxml_default_substitute_entities_set, 1);
  rb_define_module_function(mXML, "default_tree_indent_string", rxml_default_tree_indent_string_get, 0);
  rb_define_module_function(mXML, "default_tree_indent_string=", rxml_default_tree_indent_string_set, 1);
  rb_define_module_function(mXML, "default_validity_checking", rxml_default_validity_checking_get, 0);
  rb_define_module_function(mXML, "default_validity_checking=", rxml_default_validity_checking_set, 1);
  rb_define_module_function(mXML, "default_warnings", rxml_default_warnings_get, 0);
  rb_define_module_function(mXML, "default_warnings=", rxml_default_warnings_set, 1);
  rb_define_module_function(mXML, "features", rxml_features, 0);
  rb_define_module_function(mXML, "indent_tree_output", rxml_indent_tree_output_get, 0);
  rb_define_module_function(mXML, "indent_tree_output=", rxml_indent_tree_output_set, 1);
  rb_define_module_function(mXML, "memory_dump", rxml_memory_dump, 0);
  rb_define_module_function(mXML, "memory_used", rxml_memory_used, 0);
}
