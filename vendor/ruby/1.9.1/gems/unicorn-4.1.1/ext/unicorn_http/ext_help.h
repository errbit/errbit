#ifndef ext_help_h
#define ext_help_h

#ifndef RSTRING_PTR
#define RSTRING_PTR(s) (RSTRING(s)->ptr)
#endif /* !defined(RSTRING_PTR) */
#ifndef RSTRING_LEN
#define RSTRING_LEN(s) (RSTRING(s)->len)
#endif /* !defined(RSTRING_LEN) */

#ifndef HAVE_RB_STR_SET_LEN
#  ifdef RUBINIUS
#    error we should never get here with current Rubinius (1.x)
#  endif
/* this is taken from Ruby 1.8.7, 1.8.6 may not have it */
static void rb_18_str_set_len(VALUE str, long len)
{
  RSTRING(str)->len = len;
  RSTRING(str)->ptr[len] = '\0';
}
#  define rb_str_set_len(str,len) rb_18_str_set_len(str,len)
#endif /* !defined(HAVE_RB_STR_SET_LEN) */

/* not all Ruby implementations support frozen objects (Rubinius does not) */
#if defined(OBJ_FROZEN)
#  define assert_frozen(f) assert(OBJ_FROZEN(f) && "unfrozen object")
#else
#  define assert_frozen(f) do {} while (0)
#endif /* !defined(OBJ_FROZEN) */

#if !defined(OFFT2NUM)
#  if SIZEOF_OFF_T == SIZEOF_LONG
#    define OFFT2NUM(n) LONG2NUM(n)
#  else
#    define OFFT2NUM(n) LL2NUM(n)
#  endif
#endif /* ! defined(OFFT2NUM) */

#if !defined(SIZET2NUM)
#  if SIZEOF_SIZE_T == SIZEOF_LONG
#    define SIZET2NUM(n) ULONG2NUM(n)
#  else
#    define SIZET2NUM(n) ULL2NUM(n)
#  endif
#endif /* ! defined(SIZET2NUM) */

#if !defined(NUM2SIZET)
#  if SIZEOF_SIZE_T == SIZEOF_LONG
#    define NUM2SIZET(n) ((size_t)NUM2ULONG(n))
#  else
#    define NUM2SIZET(n) ((size_t)NUM2ULL(n))
#  endif
#endif /* ! defined(NUM2SIZET) */

#ifndef HAVE_RB_STR_MODIFY
#  define rb_str_modify(x) do {} while (0)
#endif /* ! defined(HAVE_RB_STR_MODIFY) */

static inline int str_cstr_eq(VALUE val, const char *ptr, long len)
{
  return (RSTRING_LEN(val) == len && !memcmp(ptr, RSTRING_PTR(val), len));
}

#define STR_CSTR_EQ(val, const_str) \
  str_cstr_eq(val, const_str, sizeof(const_str) - 1)

/* strcasecmp isn't locale independent */
static int str_cstr_case_eq(VALUE val, const char *ptr, long len)
{
  if (RSTRING_LEN(val) == len) {
    const char *v = RSTRING_PTR(val);

    for (; len--; ++ptr, ++v) {
      if ((*ptr == *v) || (*v >= 'A' && *v <= 'Z' && (*v | 0x20) == *ptr))
        continue;
      return 0;
    }
    return 1;
  }
  return 0;
}

#define STR_CSTR_CASE_EQ(val, const_str) \
  str_cstr_case_eq(val, const_str, sizeof(const_str) - 1)

#endif /* ext_help_h */
