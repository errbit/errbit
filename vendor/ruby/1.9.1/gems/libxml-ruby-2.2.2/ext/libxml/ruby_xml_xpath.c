/*
 * Document-class: LibXML::XML::XPath
 *
 * The XML::XPath module is used to query XML documents. It is
 * usually accessed via the XML::Document#find or
 * XML::Node#find methods.  For example:
 *
 *  document.find('/foo', namespaces) -> XML::XPath::Object
 *
 * The optional namespaces parameter can be a string, array or
 * hash table.
 *
 *   document.find('/foo', 'xlink:http://www.w3.org/1999/xlink')
 *   document.find('/foo', ['xlink:http://www.w3.org/1999/xlink',
 *                          'xi:http://www.w3.org/2001/XInclude')
 *   document.find('/foo', 'xlink' => 'http://www.w3.org/1999/xlink',
 *                             'xi' => 'http://www.w3.org/2001/XInclude')
 *
 *
 * === Working With Default Namespaces
 *
 * Finding namespaced elements and attributes can be tricky.
 * Lets work through an example of a document with a default
 * namespace:
 *
 *  <?xml version="1.0" encoding="utf-8"?>
 *  <feed xmlns="http://www.w3.org/2005/Atom">
 *    <title type="text">Phil Bogle's Contacts</title>
 *  </feed>
 *
 * To find nodes you must define the atom namespace for
 * libxml.  One way to do this is:
 *
 *   node = doc.find('atom:title', 'atom:http://www.w3.org/2005/Atom')
 *
 * Alternatively, you can register the default namespace like this:
 *
 *   doc.root.namespaces.default_prefix = 'atom'
 *   node = doc.find('atom:title')
 *
 * === More Complex Namespace Examples
 *
 * Lets work through some more complex examples using the
 * following xml document:
 *
 *  <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
 *    <soap:Body>
 *      <getManufacturerNamesResponse xmlns="http://services.somewhere.com">
 *        <IDAndNameList xmlns="http://services.somewhere.com">
 *          <ns1:IdAndName xmlns:ns1="http://domain.somewhere.com"/>
 *        </IDAndNameList>
 *      </getManufacturerNamesResponse>
 *  </soap:Envelope>
 *
 *  # Since the soap namespace is defined on the root
 *  # node we can directly use it.
 *  doc.find('/soap:Envelope')
 *
 *  # Since the ns1 namespace is not defined on the root node
 *  # we have to first register it with the xpath engine.
 *  doc.find('//ns1:IdAndName',
 *           'ns1:http://domain.somewhere.com')
 *
 *  # Since the getManufacturerNamesResponse element uses a default
 *  # namespace we first have to give it a prefix and register
 *  # it with the xpath engine.
 *  doc.find('//ns:getManufacturerNamesResponse',
 *            'ns:http://services.somewhere.com')
 *
 *  # Here is an example showing a complex namespace aware
 *  # xpath expression.
 *  doc.find('/soap:Envelope/soap:Body/ns0:getManufacturerNamesResponse/ns0:IDAndNameList/ns1:IdAndName',
 *  ['ns0:http://services.somewhere.com', 'ns1:http://domain.somewhere.com'])
*/


#include "ruby_libxml.h"

VALUE mXPath;

VALUE
rxml_xpath_to_value(xmlXPathContextPtr xctxt, xmlXPathObjectPtr xobject) {
  VALUE result;
  int type;

  if (xobject == NULL) {
    /* xmlLastError is different than xctxt->lastError.  Use
     xmlLastError since it has the message set while xctxt->lastError
     does not. */
    xmlErrorPtr xerror = xmlGetLastError();
    rxml_raise(xerror);
  }

  switch (type = xobject->type) {
    case XPATH_NODESET:
      result = rxml_xpath_object_wrap(xctxt->doc, xobject);
      break;
    case XPATH_BOOLEAN:
      result = (xobject->boolval != 0) ? Qtrue : Qfalse;
      xmlXPathFreeObject(xobject);
      break;
    case XPATH_NUMBER:
      result = rb_float_new(xobject->floatval);
      xmlXPathFreeObject(xobject);
      break;
    case XPATH_STRING:
      result = rxml_new_cstr((const char*)xobject->stringval, xctxt->doc->encoding);
      xmlXPathFreeObject(xobject);
      break;
    default:
      xmlXPathFreeObject(xobject);
      rb_raise(rb_eTypeError,
        "can't convert XPath object of type %d to Ruby value", type
      );
  }

  return result;
}

xmlXPathObjectPtr
rxml_xpath_from_value(VALUE value) {
  xmlXPathObjectPtr result = NULL;

  switch (TYPE(value)) {
    case T_TRUE:
    case T_FALSE:
      result = xmlXPathNewBoolean(RTEST(value));
      break;
    case T_FIXNUM:
    case T_FLOAT:
      result = xmlXPathNewFloat(NUM2DBL(value));
      break;
    case T_STRING:
      result = xmlXPathWrapString(xmlStrdup((const xmlChar *)StringValuePtr(value)));
      break;
    case T_NIL:
      result = xmlXPathNewNodeSet(NULL);
      break;
    case T_ARRAY: {
      int i, j;
      result = xmlXPathNewNodeSet(NULL);

      for (i = RARRAY_LEN(value); i > 0; i--) {
        xmlXPathObjectPtr obj = rxml_xpath_from_value(rb_ary_shift(value));

        if ((obj->nodesetval != NULL) && (obj->nodesetval->nodeNr != 0)) {
          for (j = 0; j < obj->nodesetval->nodeNr; j++) {
            xmlXPathNodeSetAdd(result->nodesetval, obj->nodesetval->nodeTab[j]);
          }
        }
      }
      break;
    }
    default:
      rb_raise(rb_eTypeError,
        "can't convert object of type %s to XPath object", rb_obj_classname(value)
      );
  }

  return result;
}

void rxml_init_xpath(void)
{
  mXPath = rb_define_module_under(mXML, "XPath");

  /* 0: Undefined value. */
  rb_define_const(mXPath, "UNDEFINED", INT2NUM(XPATH_UNDEFINED));
  /* 1: A nodeset, will be wrapped by XPath Object. */
  rb_define_const(mXPath, "NODESET", INT2NUM(XPATH_NODESET));
  /* 2: A boolean value. */
  rb_define_const(mXPath, "BOOLEAN", INT2NUM(XPATH_BOOLEAN));
  /* 3: A numeric value. */
  rb_define_const(mXPath, "NUMBER", INT2NUM(XPATH_NUMBER));
  /* 4: A string value. */
  rb_define_const(mXPath, "STRING", INT2NUM(XPATH_STRING));
  /* 5: An xpointer point */
  rb_define_const(mXPath, "POINT", INT2NUM(XPATH_POINT));
  /* 6: An xpointer range */
  rb_define_const(mXPath, "RANGE", INT2NUM(XPATH_RANGE));
  /* 7: An xpointer location set */
  rb_define_const(mXPath, "LOCATIONSET", INT2NUM(XPATH_LOCATIONSET));
  /* 8: XPath user type */
  rb_define_const(mXPath, "USERS", INT2NUM(XPATH_USERS));
  /* 9: An XSLT value tree, non modifiable */
  rb_define_const(mXPath, "XSLT_TREE", INT2NUM(XPATH_XSLT_TREE));
}
