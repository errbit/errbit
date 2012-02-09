#ifndef _INPUT_CBG_
#define _INPUT_CBG_

void rxml_init_input_callbacks(void);

typedef struct ic_doc_context {
    char *buffer;
    char *bpos;
    int remaining;
} ic_doc_context;

typedef struct ic_scheme {
    char *scheme_name;
    VALUE class;
    int name_len;

    struct ic_scheme *next_scheme;
} ic_scheme;

#endif
