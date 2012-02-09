#ifndef __RXML_XPATH_OBJECT__
#define __RXML_XPATH_OBJECT__

extern VALUE cXMLXPathObject;

typedef struct rxml_xpath_object
{
  xmlDocPtr xdoc;
  xmlXPathObjectPtr xpop;
  VALUE nsnodes;
} rxml_xpath_object;


void rxml_init_xpath_object(void);
VALUE rxml_xpath_object_wrap(xmlDocPtr xdoc, xmlXPathObjectPtr xpop);

#endif
