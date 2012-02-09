#include "ruby_libxml.h"
#include <string.h>
#include <libxml/xmlIO.h>

/*
 int         xmlRegisterInputCallbacks       (xmlInputMatchCallback matchFunc,
                                              xmlInputOpenCallback openFunc,
                                              xmlInputReadCallback readFunc,
                                              xmlInputCloseCallback closeFunc);


 int         (*xmlInputMatchCallback)        (char const *filename);
 void*       (*xmlInputOpenCallback)         (char const *filename);
 int         (*xmlInputReadCallback)         (void *context,
 char *buffer,
 int len);
 int         (*xmlInputCloseCallback)        (void *context);
 */

typedef struct deb_doc_context
{
  char *buffer;
  char *bpos;
  int remaining;
} deb_doc_context;

int deb_Match(char const *filename)
{
  fprintf(stderr, "deb_Match: %s\n", filename);
  if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "deb://", 6))
  {
    return (1);
  }
  return (0);
}

void* deb_Open(char const *filename)
{
  deb_doc_context *deb_doc;
  VALUE res;

  deb_doc = (deb_doc_context*) malloc(sizeof(deb_doc_context));

  res = rb_funcall(rb_funcall(rb_mKernel, rb_intern("const_get"), 1,
      rb_str_new2("DEBSystem")), rb_intern("document_query"), 1, rb_str_new2(filename));
  deb_doc->buffer = strdup(StringValuePtr(res));
  //deb_doc->buffer = strdup("<serepes>serepes</serepes>");

  deb_doc->bpos = deb_doc->buffer;
  deb_doc->remaining = strlen(deb_doc->buffer);
  return deb_doc;
}

int deb_Read(void *context, char *buffer, int len)
{
  deb_doc_context *deb_doc;
  int ret_len;
  deb_doc = (deb_doc_context*) context;

  if (len >= deb_doc->remaining)
  {
    ret_len = deb_doc->remaining;
  }
  else
  {
    ret_len = len;
  }
  deb_doc->remaining -= ret_len;
  strncpy(buffer, deb_doc->bpos, ret_len);
  deb_doc->bpos += ret_len;

  return ret_len;
}

int deb_Close(void *context)
{
  free(((deb_doc_context*) context)->buffer);
  free(context);
  return 1;
}

void deb_register_cbg()
{
  xmlRegisterInputCallbacks(deb_Match, deb_Open, deb_Read, deb_Close);
}
