#ifndef __RXML_DTD__
#define __RXML_DTD__

extern VALUE cXMLDtd;

void  rxml_init_dtd(void);
VALUE rxml_dtd_wrap(xmlDtdPtr xdtd);

#endif
