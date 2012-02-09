/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RXML_ENCODING__
#define __RXML_ENCODING__

extern VALUE mXMLEncoding;

void rxml_init_encoding();

// Ruby 1.8/1.9 encoding compatibility
VALUE rxml_new_cstr(const char* xstr, const char* xencoding);

#ifdef HAVE_RUBY_ENCODING_H
rb_encoding* rxml_xml_encoding_to_rb_encoding(VALUE klass, xmlCharEncoding xmlEncoding);
#endif

#endif
