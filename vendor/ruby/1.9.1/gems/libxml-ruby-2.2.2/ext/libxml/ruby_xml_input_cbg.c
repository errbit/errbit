/* Author: Martin Povolny (xpovolny@fi.muni.cz) */

#include "ruby_libxml.h"
#include "ruby_xml_input_cbg.h"

/* Document-class: LibXML::XML::InputCallbacks
 *
 * Support for adding custom scheme handlers. */

static ic_scheme *first_scheme = 0;

int ic_match(char const *filename)
{
  ic_scheme *scheme;

  //fprintf( stderr, "ic_match: %s\n", filename );

  scheme = first_scheme;
  while (0 != scheme)
  {
    if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST scheme->scheme_name, scheme->name_len))
    {
      return 1;
    }
    scheme = scheme->next_scheme;
  }
  return 0;
}

void* ic_open(char const *filename)
{
  ic_doc_context *ic_doc;
  ic_scheme *scheme;
  VALUE res;

  scheme = first_scheme;
  while (0 != scheme)
  {
    if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST scheme->scheme_name, scheme->name_len))
    {
      ic_doc = (ic_doc_context*) malloc(sizeof(ic_doc_context));

      res = rb_funcall(scheme->class, rb_intern("document_query"), 1,
          rb_str_new2(filename));

      ic_doc->buffer = strdup(StringValuePtr(res));

      ic_doc->bpos = ic_doc->buffer;
      ic_doc->remaining = strlen(ic_doc->buffer);
      return ic_doc;
    }
    scheme = scheme->next_scheme;
  }
  return 0;
}

int ic_read(void *context, char *buffer, int len)
{
  ic_doc_context *ic_doc;
  int ret_len;
  ic_doc = (ic_doc_context*) context;

  if (len >= ic_doc->remaining)
  {
    ret_len = ic_doc->remaining;
  }
  else
  {
    ret_len = len;
  }
  ic_doc->remaining -= ret_len;
  strncpy(buffer, ic_doc->bpos, ret_len);
  ic_doc->bpos += ret_len;

  return ret_len;
}

int ic_close(void *context)
{
  ruby_xfree(((ic_doc_context*) context)->buffer);
  ruby_xfree(context);
  return 1;
}

/*
 * call-seq:
 *    register
 *
 * Register a new set of I/O callback for handling parser input.
 */
static VALUE input_callbacks_register_input_callbacks()
{
  xmlRegisterInputCallbacks(ic_match, ic_open, ic_read, ic_close);
  return (Qtrue);
}

/*
 * call-seq:
 *    add_scheme
 *
 * No documentation available.
 */
static VALUE input_callbacks_add_scheme(VALUE self, VALUE scheme_name,
    VALUE class)
{
  ic_scheme *scheme;

  Check_Type(scheme_name, T_STRING);

  scheme = (ic_scheme*) malloc(sizeof(ic_scheme));
  scheme->next_scheme = 0;
  scheme->scheme_name = strdup(StringValuePtr(scheme_name)); /* TODO alloc, dealloc */
  scheme->name_len = strlen(scheme->scheme_name);
  scheme->class = class; /* TODO alloc, dealloc */

  //fprintf( stderr, "registered: %s, %d, %s\n", scheme->scheme_name, scheme->name_len, scheme->class );

  if (0 == first_scheme)
    first_scheme = scheme;
  else
  {
    ic_scheme *pos;
    pos = first_scheme;
    while (0 != pos->next_scheme)
      pos = pos->next_scheme;
    pos->next_scheme = scheme;
  }

  return (Qtrue);
}

/*
 * call-seq:
 *    remove_scheme
 *
 * No documentation available.
 */
static VALUE input_callbacks_remove_scheme(VALUE self, VALUE scheme_name)
{
  char *name;
  ic_scheme *save_scheme, *scheme;

  Check_Type(scheme_name, T_STRING);
  name = StringValuePtr(scheme_name);

  if (0 == first_scheme)
    return Qfalse;

  if (!strncmp(name, first_scheme->scheme_name, first_scheme->name_len))
  {
    save_scheme = first_scheme->next_scheme;

    ruby_xfree(first_scheme->scheme_name);
    ruby_xfree(first_scheme);

    first_scheme = save_scheme;
    return Qtrue;
  }

  scheme = first_scheme;
  while (0 != scheme->next_scheme)
  {
    if (!strncmp(name, scheme->next_scheme->scheme_name,
        scheme->next_scheme->name_len))
    {
      save_scheme = scheme->next_scheme->next_scheme;

      ruby_xfree(scheme->next_scheme->scheme_name);
      ruby_xfree(scheme->next_scheme);

      scheme->next_scheme = save_scheme;
      return Qtrue;
    }
    scheme = scheme->next_scheme;
  }
  return Qfalse;
}

void rxml_init_input_callbacks(void)
{
  VALUE cInputCallbacks;
  cInputCallbacks = rb_define_class_under(mXML, "InputCallbacks", rb_cObject);

  /* Class Methods */
  rb_define_singleton_method(cInputCallbacks, "register",
      input_callbacks_register_input_callbacks, 0);
  rb_define_singleton_method(cInputCallbacks, "add_scheme",
      input_callbacks_add_scheme, 2);
  rb_define_singleton_method(cInputCallbacks, "remove_scheme",
      input_callbacks_remove_scheme, 1);
}
