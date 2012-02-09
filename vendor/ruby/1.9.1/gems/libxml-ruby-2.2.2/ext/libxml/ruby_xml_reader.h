/* Copyright (c) 2006 Apple Computer Inc.
 * Please see the LICENSE file for copyright and distribution information. */

#ifndef __RXML_READER__
#define __RXML_READER__

#include <libxml/xmlreader.h>
#include <libxml/xmlschemas.h>

extern VALUE cXMLReader;

void rxml_init_reader(void);

/* Exported to be used by XML::Document#reader */
VALUE rxml_reader_new_walker(VALUE self, VALUE doc);

#endif /* __rxml_READER__ */
