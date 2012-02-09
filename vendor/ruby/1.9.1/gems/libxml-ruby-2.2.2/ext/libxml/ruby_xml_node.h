/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RXML_NODE__
#define __RXML_NODE__

extern VALUE cXMLNode;

void rxml_init_node(void);
void rxml_node_mark(xmlNodePtr xnode);
VALUE rxml_node_wrap(xmlNodePtr xnode);
#endif
