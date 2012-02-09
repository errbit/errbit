/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RXML_ATTRIBUTES__
#define __RXML_ATTRIBUTES__

extern VALUE cXMLAttributesibutes;

void rxml_init_attributes(void);
VALUE rxml_attributes_new(xmlNodePtr xnode);

VALUE rxml_attributes_attribute_get(VALUE self, VALUE name);
VALUE rxml_attributes_attribute_set(VALUE self, VALUE name, VALUE value);


#endif
