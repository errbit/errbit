/*
Ruby 1.9 version: (7/20/2009, Mark Moseley, mark@fast-software.com)

   Now works with Ruby-1.9.1. Tested with p129 and p243.

   This does not (and can not) function identically to the 1.8 version. 
   Line numbers are ordered differently. But ruby-debug doesn't seem 
   to mind the difference.

   Also, 1.9 does not number lines with a "begin" statement.

   All this 1.9 version does is compile into bytecode, disassemble it
   using rb_iseq_disasm(), and parse the text output. This isn't a
   great solution; it will break if the disassembly format changes.
   Walking the iseq tree and decoding each instruction is pretty hairy,
   though, so until I have a really compelling reason to go that route, 
   I'll leave it at this.
*/
#include <ruby.h>
#include <version.h>
#include <vm_core.h>
#include "trace_nums.h"

VALUE mTraceLineNumbers;

/* Return a list of trace hook line numbers for the string in Ruby source src*/
static VALUE 
lnums_for_str(VALUE self, VALUE src)
{
  VALUE result = rb_ary_new(); /* The returned array of line numbers. */
  int len;
  char *token;
  char *disasm;
  rb_thread_t *th;
  VALUE iseqval;
  VALUE disasm_val;

  StringValue(src); /* Check that src is a string. */
  th = GET_THREAD();

  /* First compile to bytecode, using the method in eval_string_with_cref() in vm_eval.c */
  th->parse_in_eval++;
  th->mild_compile_error++;
  iseqval = rb_iseq_compile(src, rb_str_new_cstr("(numbers_for_str)"), INT2FIX(1));
  th->mild_compile_error--;
  th->parse_in_eval--;

  /* Disassemble the bytecode into text and parse into lines */
  disasm_val = rb_iseq_disasm(iseqval);
  if (disasm_val == Qnil)
    return(result);

  disasm = (char*)malloc(strlen(RSTRING_PTR(disasm_val))+1);
  strcpy(disasm, RSTRING_PTR(disasm_val));

  for (token = strtok(disasm, "\n"); token != NULL; token = strtok(NULL, "\n")) 
  {
    /* look only for lines tracing RUBY_EVENT_LINE (1) */
    if (strstr(token, "trace            1 ") == NULL)
      continue;
    len = strlen(token) - 1;
    if (token[len] != ')') 
      continue;
    len--;
    if ((token[len] == '(') || (token[len] == ' '))
      continue;
      
    for (; len > 0; len--)
    {
      if (token[len] == ' ') 
        continue;
      if ((token[len] >= '0') && (token[len] <= '9')) 
        continue;
      if (token[len] == '(')
        rb_ary_push(result, INT2NUM(atoi(token + len + 1))); /* trace found */

      break;
    }
  }

  free(disasm);
  return result;
}

void Init_trace_nums19(void)
{
    mTraceLineNumbers = rb_define_module("TraceLineNumbers");
    rb_define_module_function(mTraceLineNumbers, "lnums_for_str", 
			      lnums_for_str, 1);
}
