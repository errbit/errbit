#include "ruby_libxml.h"
#include "ruby_xml_dtd.h"

/*
 * Document-class: LibXML::XML::Dtd
 *
 * The XML::Dtd class is used to prepare DTD's for validation of xml
 * documents.
 *
 * DTDs can be created from a string or a pair of public and system identifiers.
 * Once a Dtd object is instantiated, an XML document can be validated by the
 * XML::Document#validate method providing the XML::Dtd object as parameeter.
 * The method will raise an exception if the document is
 * not valid.
 *
 * Basic usage:
 *
 *  # parse DTD
 *  dtd = XML::Dtd.new(<<EOF)
 *  <!ELEMENT root (item*) >
 *  <!ELEMENT item (#PCDATA) >
 *  EOF
 *
 *  # parse xml document to be validated
 *  instance = XML::Document.file('instance.xml')
 *
 *  # validate
 *  instance.validate(dtd)
 */

VALUE cXMLDtd;

void rxml_dtd_free(xmlDtdPtr xdtd)
{
  /* Set _private to NULL so that we won't reuse the
   same, freed, Ruby wrapper object later.*/
  xdtd->_private = NULL;

  if (xdtd->doc == NULL && xdtd->parent == NULL)
    xmlFreeDtd(xdtd);
}

void rxml_dtd_mark(xmlDtdPtr xdtd)
{
  if (xdtd == NULL)
    return;

  if (xdtd->_private == NULL)
  {
    rb_warning("XmlNode is not bound! (%s:%d)", __FILE__, __LINE__);
    return;
  }

  rxml_node_mark((xmlNodePtr) xdtd);
}


static VALUE rxml_dtd_alloc(VALUE klass)
{
  return Data_Wrap_Struct(klass, rxml_dtd_mark, rxml_dtd_free, NULL);
}

VALUE rxml_dtd_wrap(xmlDtdPtr xdtd)
{
  VALUE result;

  // This node is already wrapped
  if (xdtd->_private != NULL)
    return (VALUE) xdtd->_private;

  result = Data_Wrap_Struct(cXMLDtd, NULL, NULL, xdtd);

  xdtd->_private = (void*) result;

  return result;
}

/*
 * call-seq:
 *    dtd.external_id -> "string"
 *
 * Obtain this dtd's external identifer (for a PUBLIC DTD).
 */
static VALUE rxml_dtd_external_id_get(VALUE self)
{
  xmlDtdPtr xdtd;
  Data_Get_Struct(self, xmlDtd, xdtd);


  if (xdtd->ExternalID == NULL)
    return (Qnil);
  else
    return (rxml_new_cstr((const char*) xdtd->ExternalID, NULL));
}

/*
 * call-seq:
 *    dtd.name -> "string"
 *
 * Obtain this dtd's name.
 */
static VALUE rxml_dtd_name_get(VALUE self)
{
  xmlDtdPtr xdtd;
  Data_Get_Struct(self, xmlDtd, xdtd);


  if (xdtd->name == NULL)
    return (Qnil);
  else
    return (rxml_new_cstr((const char*) xdtd->name, NULL));
}


/*
 * call-seq:
 *    dtd.uri -> "string"
 *
 * Obtain this dtd's URI (for a SYSTEM or PUBLIC DTD).
 */
static VALUE rxml_dtd_uri_get(VALUE self)
{
  xmlDtdPtr xdtd;
  Data_Get_Struct(self, xmlDtd, xdtd);


  if (xdtd->SystemID == NULL)
    return (Qnil);
  else
    return (rxml_new_cstr((const char*) xdtd->SystemID, NULL));
}

/*
 * call-seq:
 *    XML::Dtd.new("DTD string") -> dtd
 *    XML::Dtd.new("public", "system") -> dtd
 *    XML::Dtd.new("name", "public", "system", document) -> external subset dtd
 *    XML::Dtd.new("name", "public", "system", document, false) -> internal subset dtd
 *    XML::Dtd.new("name", "public", "system", document, true) -> internal subset dtd
 *
 * Create a new Dtd from the specified public and system
 * identifiers.
 */
static VALUE rxml_dtd_initialize(int argc, VALUE *argv, VALUE self)
{
  VALUE external, system, dtd_string;
  xmlParserInputBufferPtr buffer;
  xmlCharEncoding enc = XML_CHAR_ENCODING_NONE;
  xmlChar *new_string;
  xmlDtdPtr xdtd;

  // 1 argument -- string                            --> parsujeme jako dtd
  // 2 arguments -- public, system                   --> bude se hledat
  // 3 arguments -- public, system, name             --> creates an external subset (any parameter may be nil)
  // 4 arguments -- public, system, name, doc        --> creates an external subset (any parameter may be nil)
  // 5 arguments -- public, system, name, doc, true  --> creates an internal subset (all but last parameter may be nil)
  switch (argc)
  {
  case 3:
  case 4:
  case 5: {
      VALUE name, doc, internal;
      const xmlChar *xname = NULL, *xpublic = NULL, *xsystem = NULL;
      xmlDocPtr xdoc = NULL;

      rb_scan_args(argc, argv, "32", &external, &system, &name, &doc, &internal);

      if (external != Qnil) {
        Check_Type(external, T_STRING);
        xpublic = (const xmlChar*) StringValuePtr(external);
      }
      if (system != Qnil) {
        Check_Type(system, T_STRING);
        xsystem = (const xmlChar*) StringValuePtr(system);
      }
      if (name != Qnil) {
        Check_Type(name, T_STRING);
        xname = (const xmlChar*) StringValuePtr(name);
      }
      if (doc != Qnil) {
        if (rb_obj_is_kind_of(doc, cXMLDocument) == Qfalse)
          rb_raise(rb_eTypeError, "Must pass an XML::Document object");
        Data_Get_Struct(doc, xmlDoc, xdoc);
      }

      if (internal == Qnil || internal == Qfalse)
        xdtd = xmlNewDtd(xdoc, xname, xpublic, xsystem);
      else
        xdtd = xmlCreateIntSubset(xdoc, xname, xpublic, xsystem);

      if (xdtd == NULL)
        rxml_raise(&xmlLastError);

      /* Document will free this dtd now. */
      RDATA(self)->dfree = NULL;
      DATA_PTR(self) = xdtd;

      xmlSetTreeDoc((xmlNodePtr) xdtd, xdoc);
    }
    break;

  case 2:
    rb_scan_args(argc, argv, "20", &external, &system);

    Check_Type(external, T_STRING);
    Check_Type(system, T_STRING);

    xdtd = xmlParseDTD((xmlChar*) StringValuePtr(external),
        (xmlChar*) StringValuePtr(system));

    if (xdtd == NULL)
      rxml_raise(&xmlLastError);

    DATA_PTR(self) = xdtd;

    xmlSetTreeDoc((xmlNodePtr) xdtd, NULL);
    break;

  case 1:
    rb_scan_args(argc, argv, "10", &dtd_string);
    Check_Type(dtd_string, T_STRING);

    /* Note that buffer is freed by xmlParserInputBufferPush*/
    buffer = xmlAllocParserInputBuffer(enc);
    new_string = xmlStrdup((xmlChar*) StringValuePtr(dtd_string));
    xmlParserInputBufferPush(buffer, xmlStrlen(new_string),
        (const char*) new_string);

    xdtd = xmlIOParseDTD(NULL, buffer, enc);

    if (xdtd == NULL)
      rxml_raise(&xmlLastError);

    xmlFree(new_string);

    DATA_PTR(self) = xdtd;
    break;

  default:
    rb_raise(rb_eArgError, "wrong number of arguments");
  }

  return self;
}

void rxml_init_dtd()
{
  cXMLDtd = rb_define_class_under(mXML, "Dtd", rb_cObject);
  rb_define_alloc_func(cXMLDtd, rxml_dtd_alloc);
  rb_define_method(cXMLDtd, "initialize", rxml_dtd_initialize, -1);
  rb_define_method(cXMLDtd, "external_id", rxml_dtd_external_id_get, 0);
  rb_define_method(cXMLDtd, "name", rxml_dtd_name_get, 0);
  rb_define_method(cXMLDtd, "uri", rxml_dtd_uri_get, 0);

  rb_define_alias(cXMLDtd, "system_id", "uri");
}

