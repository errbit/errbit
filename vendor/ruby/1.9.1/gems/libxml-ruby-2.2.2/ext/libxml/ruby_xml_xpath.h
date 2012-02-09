/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RXML_XPATH__
#define __RXML_XPATH__

extern VALUE mXPath;

void rxml_init_xpath(void);

VALUE rxml_xpath_to_value(xmlXPathContextPtr, xmlXPathObjectPtr);
xmlXPathObjectPtr rxml_xpath_from_value(VALUE);

#endif
