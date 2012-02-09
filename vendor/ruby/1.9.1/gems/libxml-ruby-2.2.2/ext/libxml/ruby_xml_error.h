/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RXML_ERROR__
#define __RXML_ERROR__

extern VALUE eXMLError;

void rxml_init_error();
VALUE rxml_error_wrap(xmlErrorPtr xerror);
void rxml_raise(xmlErrorPtr xerror);

#endif
