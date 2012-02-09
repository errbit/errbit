/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RXML_DOCUMENT__
#define __RXML_DOCUMENT__

extern VALUE cXMLDocument;
void rxml_init_document();
VALUE rxml_document_wrap(xmlDocPtr xnode);

#endif
