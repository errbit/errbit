#include <ruby.h>
#include <stdio.h>
#include <ctype.h>
#include <vm_core.h>
#include <iseq.h>
#include <version.h>
#include <eval_intern.h>
#include <insns.inc>
#include <insns_info.inc>
#include "ruby_debug.h"

#define DEBUG_VERSION "0.11"

#define FRAME_N(n)  (&debug_context->frames[debug_context->stack_size-(n)-1])
#define GET_FRAME   (FRAME_N(check_frame_number(debug_context, frame)))

#ifndef min
#define min(x,y) ((x) < (y) ? (x) : (y))
#endif

#define STACK_SIZE_INCREMENT 128

RUBY_EXTERN int rb_vm_get_sourceline(const rb_control_frame_t *cfp); /* from vm.c */

/* from iseq.c */
#ifdef RB_ISEQ_COMPILE_6ARGS
RUBY_EXTERN VALUE rb_iseq_compile_with_option(VALUE src, VALUE file, VALUE filepath, VALUE line, VALUE opt);
#else
RUBY_EXTERN VALUE rb_iseq_compile_with_option(VALUE src, VALUE file, VALUE line, VALUE opt);
#endif

typedef struct {
    st_table *tbl;
} threads_table_t;

static VALUE tracing            = Qfalse;
static VALUE locker             = Qnil;
static VALUE post_mortem        = Qfalse;
static VALUE keep_frame_binding = Qfalse;
static VALUE debug              = Qfalse;
static VALUE track_frame_args   = Qfalse;

static VALUE last_context = Qnil;
static VALUE last_thread  = Qnil;
static debug_context_t *last_debug_context = NULL;

VALUE rdebug_threads_tbl = Qnil; /* Context for each of the threads */
VALUE mDebugger;                 /* Ruby Debugger Module object */

static VALUE opt_call_c_function;
static VALUE cThreadsTable;
static VALUE cContext;
static VALUE cDebugThread;

static VALUE rb_mObjectSpace;

static ID idAtBreakpoint;
static ID idAtCatchpoint;
static ID idAtLine;
static ID idAtReturn;
static ID idAtTracing;
static ID idList;

static int start_count = 0;
static int thnum_max = 0;
static int bkp_count = 0;
static int last_debugged_thnum = -1;
static unsigned long last_check = 0;
static unsigned long hook_count = 0;

static VALUE create_binding(VALUE);
static VALUE debug_stop(VALUE);
static void save_current_position(debug_context_t *);
static VALUE context_copy_args(debug_frame_t *);
static VALUE context_copy_locals(debug_context_t *,debug_frame_t *, VALUE);
static void context_suspend_0(debug_context_t *);
static void context_resume_0(debug_context_t *);
static void copy_scalar_args(debug_frame_t *);

typedef struct locked_thread_t {
    VALUE thread_id;
    struct locked_thread_t *next;
} locked_thread_t;

static locked_thread_t *locked_head = NULL;
static locked_thread_t *locked_tail = NULL;

/* "Step", "Next" and "Finish" do their work by saving information
   about where to stop next. reset_stopping_points removes/resets this
   information. */
inline static const char *
get_event_name(rb_event_flag_t _event)
{
  switch (_event) {
    case RUBY_EVENT_LINE:
      return "line";
    case RUBY_EVENT_CLASS:
      return "class";
    case RUBY_EVENT_END:
      return "end";
    case RUBY_EVENT_CALL:
      return "call";
    case RUBY_EVENT_RETURN:
      return "return";
    case RUBY_EVENT_C_CALL:
      return "c-call";
    case RUBY_EVENT_C_RETURN:
      return "c-return";
    case RUBY_EVENT_RAISE:
      return "raise";
    default:
      return "unknown";
  }
}

inline static void
reset_stepping_stop_points(debug_context_t *debug_context)
{
    debug_context->dest_frame = -1;
    debug_context->stop_line  = -1;
    debug_context->stop_next  = -1;
}

inline static VALUE
real_class(VALUE klass)
{
    if (klass) {
        if (TYPE(klass) == T_ICLASS) {
            return RBASIC(klass)->klass;
        }
        else if (FL_TEST(klass, FL_SINGLETON)) {
            return rb_iv_get(klass, "__attached__");
        }
    }
    return klass;
}

inline static void *
ruby_method_ptr(VALUE class, ID meth_id)
{
#ifdef RUBY_VERSION_1_9_1
    NODE *body, *method;
    st_lookup(RCLASS_M_TBL(class), meth_id, (st_data_t *)&body);
    method = (NODE *)body->u2.value;
    return (void *)method->u2.node->u1.value;
#else
    rb_method_entry_t * method;
    method = rb_method_entry(class, meth_id);
#ifdef HAVE_ST_BODY
    return (void *)method->body.cfunc.func;
#else
    return (void *)method->def->body.cfunc.func;
#endif
#endif
}

inline static VALUE
ref2id(VALUE obj)
{
    return rb_obj_id(obj);
}

static VALUE
id2ref_unprotected(VALUE id)
{
    typedef VALUE (*id2ref_func_t)(VALUE, VALUE);
    static id2ref_func_t f_id2ref = NULL;
    if(f_id2ref == NULL)
    {
        f_id2ref = (id2ref_func_t)ruby_method_ptr(rb_mObjectSpace, rb_intern("_id2ref"));
    }
    return f_id2ref(rb_mObjectSpace, id);
}

static VALUE
id2ref_error()
{
    if(debug == Qtrue)
        rb_p(rb_errinfo());
    return Qnil;
}

static VALUE
id2ref(VALUE id)
{
    return rb_rescue(id2ref_unprotected, id, id2ref_error, 0);
}

inline static VALUE
context_thread_0(debug_context_t *debug_context)
{
    return id2ref(debug_context->thread_id);
}

static int
is_in_locked(VALUE thread_id)
{
    locked_thread_t *node;

    if(!locked_head)
        return 0;

    for(node = locked_head; node != locked_tail; node = node->next)
    {
        if(node->thread_id == thread_id) return 1;
    }
    return 0;
}

static void
add_to_locked(VALUE thread)
{
    locked_thread_t *node;
    VALUE thread_id = ref2id(thread);

    if(is_in_locked(thread_id))
        return;

    node = ALLOC(locked_thread_t);
    node->thread_id = thread_id;
    node->next = NULL;
    if(locked_tail)
        locked_tail->next = node;
    locked_tail = node;
    if(!locked_head)
        locked_head = node;
}

static VALUE
remove_from_locked()
{
    VALUE thread;
    locked_thread_t *node;

    if(locked_head == NULL)
        return Qnil;
    node = locked_head;
    locked_head = locked_head->next;
    if(locked_tail == node)
        locked_tail = NULL;
    thread = id2ref(node->thread_id);
    xfree(node);
    return thread;
}

static int
threads_table_mark_keyvalue(VALUE key, VALUE value, int dummy)
{
    rb_gc_mark(value);
    return ST_CONTINUE;
}

static void
threads_table_mark(void* data)
{
    threads_table_t *threads_table = (threads_table_t*)data;
    st_foreach(threads_table->tbl, threads_table_mark_keyvalue, 0);
}

static void
threads_table_free(void* data)
{
    threads_table_t *threads_table = (threads_table_t*)data;
    st_free_table(threads_table->tbl);
    xfree(threads_table);
}

static VALUE
threads_table_create()
{
    threads_table_t *threads_table;

    threads_table = ALLOC(threads_table_t);
    threads_table->tbl = st_init_numtable();
    return Data_Wrap_Struct(cThreadsTable, threads_table_mark, threads_table_free, threads_table);
}

static int
threads_table_clear_i(VALUE key, VALUE value, VALUE dummy)
{
    return ST_DELETE;
}

static void
threads_table_clear(VALUE table)
{
    threads_table_t *threads_table;

    Data_Get_Struct(table, threads_table_t, threads_table);
    st_foreach(threads_table->tbl, threads_table_clear_i, 0);
}

static VALUE
is_thread_alive(VALUE thread)
{
    typedef VALUE (*thread_alive_func_t)(VALUE);
    static thread_alive_func_t f_thread_alive = NULL;
    if(!f_thread_alive)
    {
        f_thread_alive = (thread_alive_func_t)ruby_method_ptr(rb_cThread, rb_intern("alive?"));
    }
    return f_thread_alive(thread);
}

static int
threads_table_check_i(VALUE key, VALUE value, VALUE dummy)
{
    VALUE thread;

    thread = id2ref(key);
    if(!rb_obj_is_kind_of(thread, rb_cThread))
    {
        return ST_DELETE;
    }
    if(rb_protect(is_thread_alive, thread, 0) != Qtrue)
    {
        return ST_DELETE;
    }
    return ST_CONTINUE;
}

static void
check_thread_contexts()
{
    threads_table_t *threads_table;

    Data_Get_Struct(rdebug_threads_tbl, threads_table_t, threads_table);
    st_foreach(threads_table->tbl, threads_table_check_i, 0);
}

/*
 *   call-seq:
 *      Debugger.started? -> bool
 *
 *   Returns +true+ the debugger is started.
 */
static VALUE
debug_is_started(VALUE self)
{
    return IS_STARTED ? Qtrue : Qfalse;
}

static void
debug_context_mark(void *data)
{
    debug_frame_t *frame;
    int i;

    debug_context_t *debug_context = (debug_context_t *)data;
    for(i = 0; i < debug_context->stack_size; i++)
    {
        frame = &(debug_context->frames[i]);
        rb_gc_mark(frame->binding);
        rb_gc_mark(frame->self);
        rb_gc_mark(frame->arg_ary);
        if(frame->dead)
        {
            rb_gc_mark(frame->info.copy.locals);
            rb_gc_mark(frame->info.copy.args);
        }
    }
    rb_gc_mark(debug_context->breakpoint);
}

static void
debug_context_free(void *data)
{
    debug_context_t *debug_context = (debug_context_t *)data;
    xfree(debug_context->frames);
}

static VALUE
debug_context_create(VALUE thread)
{
    debug_context_t *debug_context;

    debug_context = ALLOC(debug_context_t);
    debug_context-> thnum = ++thnum_max;

    debug_context->last_file = NULL;
    debug_context->last_line = 0;
    debug_context->flags = 0;

    debug_context->stop_next = -1;
    debug_context->dest_frame = -1;
    debug_context->stop_line = -1;
    debug_context->stop_frame = -1;
    debug_context->stop_reason = CTX_STOP_NONE;
    debug_context->stack_len = STACK_SIZE_INCREMENT;
    debug_context->frames = ALLOC_N(debug_frame_t, STACK_SIZE_INCREMENT);
    debug_context->stack_size = 0;
    debug_context->thread_id = ref2id(thread);
    debug_context->breakpoint = Qnil;
    debug_context->jump_pc = NULL;
    debug_context->jump_cfp = NULL;
    debug_context->old_iseq_catch = NULL;
    debug_context->thread_pause = 0;
    if(rb_obj_class(thread) == cDebugThread)
        CTX_FL_SET(debug_context, CTX_FL_IGNORE);
    return Data_Wrap_Struct(cContext, debug_context_mark, debug_context_free, debug_context);
}

static VALUE
debug_context_dup(debug_context_t *debug_context, VALUE self)
{
    debug_context_t *new_debug_context;
    debug_frame_t *new_frame, *old_frame;
    int i;

    new_debug_context = ALLOC(debug_context_t);
    memcpy(new_debug_context, debug_context, sizeof(debug_context_t));
    new_debug_context->stop_next = -1;
    new_debug_context->dest_frame = -1;
    new_debug_context->stop_line = -1;
    new_debug_context->stop_frame = -1;
    new_debug_context->breakpoint = Qnil;
    CTX_FL_SET(new_debug_context, CTX_FL_DEAD);
    new_debug_context->frames = ALLOC_N(debug_frame_t, debug_context->stack_size);
    new_debug_context->stack_len = debug_context->stack_size;
    memcpy(new_debug_context->frames, debug_context->frames, sizeof(debug_frame_t) * debug_context->stack_size);
    for(i = 0; i < debug_context->stack_size; i++)
    {
        new_frame = &(new_debug_context->frames[i]);
        old_frame = &(debug_context->frames[i]);
        new_frame->dead = 1;
        new_frame->info.copy.args = context_copy_args(old_frame);
        new_frame->info.copy.locals = context_copy_locals(debug_context, old_frame, self);
    }
    return Data_Wrap_Struct(cContext, debug_context_mark, debug_context_free, new_debug_context);
}

static void
thread_context_lookup(VALUE thread, VALUE *context, debug_context_t **debug_context, int create)
{
    threads_table_t *threads_table;
    VALUE thread_id;
    debug_context_t *l_debug_context;

    debug_check_started();

    if(last_thread == thread && last_context != Qnil)
    {
        *context = last_context;
        if(debug_context)
            *debug_context = last_debug_context;
        return;
    }
    thread_id = ref2id(thread);
    Data_Get_Struct(rdebug_threads_tbl, threads_table_t, threads_table);
    if(!st_lookup(threads_table->tbl, thread_id, context))
    {
        if (create)
        {
            *context = debug_context_create(thread);
            st_insert(threads_table->tbl, thread_id, *context);
        }
        else
        {
            *context = 0;
            if (debug_context)
                *debug_context = NULL;
            return;
        }
    }

    Data_Get_Struct(*context, debug_context_t, l_debug_context);
    if(debug_context)
        *debug_context = l_debug_context;

    last_thread = thread;
    last_context = *context;
    last_debug_context = l_debug_context;
}

static VALUE
call_at_line_unprotected(VALUE args)
{
    VALUE context;
    context = *RARRAY_PTR(args);
    return rb_funcall2(context, idAtLine, RARRAY_LEN(args) - 1, RARRAY_PTR(args) + 1);
}

static VALUE
call_at_line(VALUE context, debug_context_t *debug_context, VALUE file, VALUE line)
{
    VALUE args;
    
    last_debugged_thnum = debug_context->thnum;
    save_current_position(debug_context);

    args = rb_ary_new3(3, context, file, line);
    return rb_protect(call_at_line_unprotected, args, 0);
}

static void
save_call_frame(rb_event_flag_t _event, debug_context_t *debug_context, VALUE self, char *file, int line, ID mid)
{
    VALUE binding;
    debug_frame_t *debug_frame;
    int frame_n;

    binding = self && RTEST(keep_frame_binding)? create_binding(self) : Qnil;

    frame_n = debug_context->stack_size++;
    if(frame_n >= debug_context->stack_len)
    {
        debug_context->stack_len += STACK_SIZE_INCREMENT;
        debug_context->frames = REALLOC_N(debug_context->frames, debug_frame_t, debug_context->stack_len);
    }
    debug_frame = &debug_context->frames[frame_n];
    debug_frame->file = file;
    debug_frame->line = line;
    debug_frame->binding = binding;
    debug_frame->id = mid;
    debug_frame->orig_id = mid;
    debug_frame->dead = 0;
    debug_frame->self = self;
    debug_frame->arg_ary = Qnil;
    debug_frame->argc = GET_THREAD()->cfp->iseq->argc;
    debug_frame->info.runtime.cfp = GET_THREAD()->cfp;
    debug_frame->info.runtime.bp = GET_THREAD()->cfp->bp;
    debug_frame->info.runtime.block_iseq = GET_THREAD()->cfp->block_iseq;
    debug_frame->info.runtime.block_pc = NULL;
    debug_frame->info.runtime.last_pc = GET_THREAD()->cfp->pc;
    if (RTEST(track_frame_args))
        copy_scalar_args(debug_frame);
}


#if defined DOSISH
#define isdirsep(x) ((x) == '/' || (x) == '\\')
#else
#define isdirsep(x) ((x) == '/')
#endif

int
filename_cmp(VALUE source, char *file)
{
    char *source_ptr, *file_ptr;
    int s_len, f_len, min_len;
    int s,f;
    int dirsep_flag = 0;

    s_len = RSTRING_LEN(source);
    f_len = strlen(file);
    min_len = min(s_len, f_len);

    source_ptr = RSTRING_PTR(source);
    file_ptr   = file;

    for( s = s_len - 1, f = f_len - 1; s >= s_len - min_len && f >= f_len - min_len; s--, f-- )
    {
        if((source_ptr[s] == '.' || file_ptr[f] == '.') && dirsep_flag)
            return 1;
        if(isdirsep(source_ptr[s]) && isdirsep(file_ptr[f]))
            dirsep_flag = 1;
#ifdef DOSISH_DRIVE_LETTER
        else if (s == 0)
            return(toupper(source_ptr[s]) == toupper(file_ptr[f]));
#endif
        else if(source_ptr[s] != file_ptr[f])
            return 0;
    }
    return 1;
}

static VALUE
create_binding(VALUE self)
{
    return(rb_binding_new());
}

inline static debug_frame_t *
get_top_frame(debug_context_t *debug_context)
{
    if(debug_context->stack_size == 0)
        return NULL;
    else
        return &(debug_context->frames[debug_context->stack_size-1]);
}

inline static void
save_top_binding(debug_context_t *debug_context, VALUE binding)
{
    debug_frame_t *debug_frame;
    debug_frame = get_top_frame(debug_context);
    if(debug_frame)
        debug_frame->binding = binding;
}

inline static void
set_frame_source(rb_event_flag_t event, debug_context_t *debug_context, VALUE self, char *file, int line, ID mid)
{
    debug_frame_t *top_frame;
    top_frame = get_top_frame(debug_context);
    if(top_frame)
    {
        if (top_frame->info.runtime.block_iseq == GET_THREAD()->cfp->iseq)
        {
            top_frame->info.runtime.block_pc = GET_THREAD()->cfp->pc;
            top_frame->binding = create_binding(self); /* block entered; need to rebind */
        }
        else if ((top_frame->info.runtime.block_pc != NULL) && (GET_THREAD()->cfp->pc == top_frame->info.runtime.block_pc))
        {
            top_frame->binding = create_binding(self); /* block re-entered; need to rebind */
        }

        top_frame->info.runtime.block_iseq = GET_THREAD()->cfp->block_iseq;
        if (event == RUBY_EVENT_LINE)
            top_frame->info.runtime.last_pc = GET_THREAD()->cfp->pc;
        top_frame->self = self;
        top_frame->file = file;
        top_frame->line = line;
        top_frame->id   = mid;
    }
}

inline static void
reset_frame_mid(debug_context_t *debug_context)
{
    debug_frame_t *top_frame;
    top_frame = get_top_frame(debug_context);
    if(top_frame)
    {
        top_frame->id = 0;
    }
}

static void
save_current_position(debug_context_t *debug_context)
{
    debug_frame_t *debug_frame;

    debug_frame = get_top_frame(debug_context);
    if(!debug_frame) return;
    debug_context->last_file = debug_frame->file;
    debug_context->last_line = debug_frame->line;
    CTX_FL_UNSET(debug_context, CTX_FL_ENABLE_BKPT);
    CTX_FL_UNSET(debug_context, CTX_FL_STEPPED);
    CTX_FL_UNSET(debug_context, CTX_FL_FORCE_MOVE);
}

inline static int
c_call_new_frame_p(VALUE klass, ID mid)
{
    klass = real_class(klass);
    if(rb_block_given_p()) return 1;
    if(klass == rb_cProc || klass == rb_mKernel || klass == rb_cModule) return 1;
    return 0;
}

static void 
call_at_line_check(VALUE self, debug_context_t *debug_context, VALUE breakpoint, VALUE context, char *file, int line)
{
    VALUE binding = self? create_binding(self) : Qnil;
    save_top_binding(debug_context, binding);

    debug_context->stop_reason = CTX_STOP_STEP;

    /* check breakpoint expression */
    if(breakpoint != Qnil)
    {
        if(!check_breakpoint_expression(breakpoint, binding))
            return;// TODO
        if(!check_breakpoint_hit_condition(breakpoint))
            return;// TODO
        if(breakpoint != debug_context->breakpoint)
        {
            debug_context->stop_reason = CTX_STOP_BREAKPOINT;
            rb_funcall(context, idAtBreakpoint, 1, breakpoint);
        }
        else
            debug_context->breakpoint = Qnil;
    }

    reset_stepping_stop_points(debug_context);
    call_at_line(context, debug_context, rb_str_new2(file), INT2FIX(line));
}

static struct iseq_catch_table_entry *
create_catch_table(debug_context_t *debug_context, unsigned long cont)
{
    struct iseq_catch_table_entry *catch_table = &debug_context->catch_table.tmp_catch_table;

    GET_THREAD()->parse_in_eval++;
    GET_THREAD()->mild_compile_error++;
    /* compiling with option Qfalse (no options) prevents debug hook calls during this catch routine */
#ifdef RB_ISEQ_COMPILE_6ARGS
    catch_table->iseq = rb_iseq_compile_with_option(
        rb_str_new_cstr(""), rb_str_new_cstr("(exception catcher)"), Qnil, INT2FIX(1), Qfalse);
#else
    catch_table->iseq = rb_iseq_compile_with_option(
        rb_str_new_cstr(""), rb_str_new_cstr("(exception catcher)"), INT2FIX(1), Qfalse);
#endif
    GET_THREAD()->mild_compile_error--;
    GET_THREAD()->parse_in_eval--;

    catch_table->type = CATCH_TYPE_RESCUE;
    catch_table->start = 0;
    catch_table->end = ULONG_MAX;
    catch_table->cont = cont;
    catch_table->sp = 0;

    return(catch_table);
}

static int
set_thread_event_flag_i(st_data_t key, st_data_t val, st_data_t flag)
{
    VALUE thval = key;
    rb_thread_t *th;
    GetThreadPtr(thval, th);
    th->event_flags |= RUBY_EVENT_VM;

    return(ST_CONTINUE);
}

static void
debug_event_hook(rb_event_flag_t event, VALUE data, VALUE self, ID mid, VALUE klass)
{
    VALUE context;
    VALUE breakpoint = Qnil, binding = Qnil;
    debug_context_t *debug_context;
    char *file = (char*)rb_sourcefile();
    int line = rb_sourceline();
    int moved = 0;
#ifdef RUBY_VERSION_1_9_1
    NODE *node = NULL;
#else
    rb_method_entry_t *me = NULL;
#endif
    rb_thread_t *thread = GET_THREAD();
    struct rb_iseq_struct *iseq = thread->cfp->iseq;

    hook_count++;

    if (((iseq == NULL) || (file == NULL)) && (event != RUBY_EVENT_RAISE))
        return;
    thread_context_lookup(thread->self, &context, &debug_context, 1);

    if ((event == RUBY_EVENT_LINE) || (event == RUBY_EVENT_CALL))
    {
        mid = iseq->defined_method_id;
        klass = iseq->klass;
    }

    if (mid == ID_ALLOCATOR) return;

#ifdef RUBY_VERSION_1_9_1
    node = rb_method_node(klass, mid);
#else
    me = rb_method_entry(klass, mid);
#endif

    /* return if thread is marked as 'ignored'.
       debugger's threads are marked this way
     */
    if(CTX_FL_TEST(debug_context, CTX_FL_IGNORE)) return;

    while(1)
    {
        /* halt execution of the current thread if the debugger
           is activated in another
         */
        while(locker != Qnil && locker != thread->self)
        {
            add_to_locked(thread->self);
            rb_thread_stop();
        }

        /* stop the current thread if it's marked as suspended */
        if(CTX_FL_TEST(debug_context, CTX_FL_SUSPEND) && locker != thread->self)
        {
            CTX_FL_SET(debug_context, CTX_FL_WAS_RUNNING);
            rb_thread_stop();
        }
        else break;
    }

    /* return if the current thread is the locker */
    if (locker != Qnil) return;

    /* only the current thread can proceed */
    locker = thread->self;

    /* restore catch tables removed for jump */
    if (debug_context->old_iseq_catch != NULL)
    {
        int i = 0;
        while (debug_context->old_iseq_catch[i].iseq != NULL)
        {
            debug_context->old_iseq_catch[i].iseq->catch_table = debug_context->old_iseq_catch[i].catch_table;
            debug_context->old_iseq_catch[i].iseq->catch_table_size = debug_context->old_iseq_catch[i].catch_table_size;
            i++;
        }
        free(debug_context->old_iseq_catch);
        debug_context->old_iseq_catch = NULL;
    }

    /* make sure all threads have event flag set so we'll get its events */
    st_foreach(thread->vm->living_threads, set_thread_event_flag_i, 0);

    /* remove any frames that are now out of scope */
    while(debug_context->stack_size > 0)
    {
        if (debug_context->frames[debug_context->stack_size - 1].info.runtime.bp <= thread->cfp->bp)
            break;
        debug_context->stack_size--;
    }

    if (debug_context->thread_pause) 
    {
        debug_context->thread_pause = 0;
        debug_context->stop_next = 1;
        debug_context->dest_frame = -1;
        moved = 1;
    }
    else
    {
        /* ignore a skipped section of code */
        if (CTX_FL_TEST(debug_context, CTX_FL_SKIPPED)) 
            goto cleanup;

        if ((event == RUBY_EVENT_LINE) && (debug_context->stack_size > 0) && 
            (get_top_frame(debug_context)->line == line) && (get_top_frame(debug_context)->info.runtime.cfp->iseq == iseq) &&
            !CTX_FL_TEST(debug_context, CTX_FL_CATCHING))
        {
            /* Sometimes duplicate RUBY_EVENT_LINE messages get generated by the compiler.
             * Ignore them. */
            goto cleanup;
        }
    }

    if(debug == Qtrue)
        fprintf(stderr, "%s:%d [%s] %s\n", file, line, get_event_name(event), rb_id2name(mid));

    /* There can be many event calls per line, but we only want
     *one* breakpoint per line. */
    if(debug_context->last_line != line || debug_context->last_file == NULL ||
       strcmp(debug_context->last_file, file) != 0)
    {
        CTX_FL_SET(debug_context, CTX_FL_ENABLE_BKPT);
        moved = 1;
    } 

    if(event != RUBY_EVENT_LINE)
        CTX_FL_SET(debug_context, CTX_FL_STEPPED);

    switch(event)
    {
    case RUBY_EVENT_LINE:
    {
        if(debug_context->stack_size == 0)
            save_call_frame(event, debug_context, self, file, line, mid);
        else
            set_frame_source(event, debug_context, self, file, line, mid);

        if (CTX_FL_TEST(debug_context, CTX_FL_CATCHING))
        {
            debug_frame_t *top_frame = get_top_frame(debug_context);
            
            if (top_frame != NULL)
            {
                rb_control_frame_t *cfp = top_frame->info.runtime.cfp;
                int hit_count;

                /* restore the proper catch table */
                cfp->iseq->catch_table_size = debug_context->catch_table.old_catch_table_size;
                cfp->iseq->catch_table = debug_context->catch_table.old_catch_table;
                
                /* send catchpoint notification */
                hit_count = INT2FIX(FIX2INT(rb_hash_aref(rdebug_catchpoints, 
                    debug_context->catch_table.mod_name)+1));
                rb_hash_aset(rdebug_catchpoints, debug_context->catch_table.mod_name, hit_count);
                debug_context->stop_reason = CTX_STOP_CATCHPOINT;
                rb_funcall(context, idAtCatchpoint, 1, debug_context->catch_table.errinfo);
                if(self && binding == Qnil)
                    binding = create_binding(self);
                save_top_binding(debug_context, binding);
                call_at_line(context, debug_context, rb_str_new2(file), INT2FIX(line));
            }

            /* now allow the next exception to be caught */
            CTX_FL_UNSET(debug_context, CTX_FL_CATCHING);
            break;
        }
        
        if(RTEST(tracing) || CTX_FL_TEST(debug_context, CTX_FL_TRACING))
            rb_funcall(context, idAtTracing, 2, rb_str_new2(file), INT2FIX(line));

        if(debug_context->dest_frame == -1 ||
            debug_context->stack_size == debug_context->dest_frame)
        {
            if(moved || !CTX_FL_TEST(debug_context, CTX_FL_FORCE_MOVE))
                debug_context->stop_next--;
            if(debug_context->stop_next < 0)
                debug_context->stop_next = -1;
            if(moved || (CTX_FL_TEST(debug_context, CTX_FL_STEPPED) && 
                        !CTX_FL_TEST(debug_context, CTX_FL_FORCE_MOVE)))
            {
                debug_context->stop_line--;
                CTX_FL_UNSET(debug_context, CTX_FL_STEPPED);
            }
        }
        else if(debug_context->stack_size < debug_context->dest_frame)
        {
            debug_context->stop_next = 0;
        }

        if(debug_context->stop_next == 0 || debug_context->stop_line == 0 ||
            (breakpoint = check_breakpoints_by_pos(debug_context, file, line)) != Qnil)
        {
            call_at_line_check(self, debug_context, breakpoint, context, file, line);
        } 
        break;
    }
    case RUBY_EVENT_CALL:
    {
        save_call_frame(event, debug_context, self, file, line, mid);
        breakpoint = check_breakpoints_by_method(debug_context, klass, mid, self);
        if(breakpoint != Qnil)
        {
            debug_frame_t *debug_frame;
            debug_frame = get_top_frame(debug_context);
            if(debug_frame)
                binding = debug_frame->binding;
            if(NIL_P(binding) && self)
                binding = create_binding(self);
            save_top_binding(debug_context, binding);

            if(!check_breakpoint_expression(breakpoint, binding))
                break;
            if(!check_breakpoint_hit_condition(breakpoint))
                break;
            if(breakpoint != debug_context->breakpoint)
            {
                debug_context->stop_reason = CTX_STOP_BREAKPOINT;
                rb_funcall(context, idAtBreakpoint, 1, breakpoint);
            }
            else
                debug_context->breakpoint = Qnil;
            call_at_line(context, debug_context, rb_str_new2(file), INT2FIX(line));
            break;
        }
        breakpoint = check_breakpoints_by_pos(debug_context, file, line);
        if (breakpoint != Qnil)
            call_at_line_check(self, debug_context, breakpoint, context, file, line);
        break;
    }
    case RUBY_EVENT_C_CALL:
    {
        if(c_call_new_frame_p(klass, mid))
            save_call_frame(event, debug_context, self, file, line, mid);
        else
            set_frame_source(event, debug_context, self, file, line, mid);
        break;
    }
    case RUBY_EVENT_C_RETURN:
    {
        /* note if a block is given we fall through! */
#ifdef RUBY_VERSION_1_9_1
        if(!node || !c_call_new_frame_p(klass, mid))
#else
        if(!me || !c_call_new_frame_p(klass, mid))
#endif
            break;
    }
    case RUBY_EVENT_RETURN:
    case RUBY_EVENT_END:
    {
        if(debug_context->stack_size == debug_context->stop_frame)
        {
            debug_context->stop_next = 1;
            debug_context->stop_frame = 0;
            /* NOTE: can't use call_at_line function here to trigger a debugger event.
               this can lead to segfault. We should only unroll the stack on this event.
             */
        }
        while(debug_context->stack_size > 0)
        {
            debug_context->stack_size--;
            if (debug_context->frames[debug_context->stack_size].info.runtime.bp <= GET_THREAD()->cfp->bp)
                break;
        }
        CTX_FL_SET(debug_context, CTX_FL_ENABLE_BKPT);

        break;
    }
    case RUBY_EVENT_CLASS:
    {
        reset_frame_mid(debug_context);
        save_call_frame(event, debug_context, self, file, line, mid);
        break;
    }
    case RUBY_EVENT_RAISE:
    {
        VALUE ancestors;
        VALUE expn_class, aclass;
        int i;

//        set_frame_source(event, debug_context, self, file, line, mid);

        if(post_mortem == Qtrue && self)
        {
            binding = create_binding(self);
            rb_ivar_set(rb_errinfo(), rb_intern("@__debug_file"), rb_str_new2(file));
            rb_ivar_set(rb_errinfo(), rb_intern("@__debug_line"), INT2FIX(line));
            rb_ivar_set(rb_errinfo(), rb_intern("@__debug_binding"), binding);
            rb_ivar_set(rb_errinfo(), rb_intern("@__debug_context"), debug_context_dup(debug_context, self));
        }

        expn_class = rb_obj_class(rb_errinfo());

        /* This code goes back to the earliest days of ruby-debug. It
           tends to disallow catching an exception via the
           "catchpoint" command. To address this one possiblilty is to
           move this after testing for catchponts. Kent however thinks
           there may be a misfeature in Ruby's eval.c: the problem was
           in the fact that Ruby doesn't reset exception flag on the
           current thread before it calls a notification handler.

           See also the #ifdef'd code below as well.
         */
#ifdef NORMAL_CODE
        if( !NIL_P(rb_class_inherited_p(expn_class, rb_eSystemExit)) )
        {
            debug_stop(mDebugger);
            break;
        }
#endif

        if (rdebug_catchpoints == Qnil ||
            (debug_context->stack_size == 0) ||
            CTX_FL_TEST(debug_context, CTX_FL_CATCHING) ||
#ifdef _ST_NEW_
            st_get_num_entries(RHASH_TBL(rdebug_catchpoints)) == 0)
#else
            (RHASH_TBL(rdebug_catchpoints)->num_entries) == 0)
#endif
            break;

        ancestors = rb_mod_ancestors(expn_class);
        for(i = 0; i < RARRAY_LEN(ancestors); i++)
        {
            VALUE mod_name;
            VALUE hit_count;

            aclass    = rb_ary_entry(ancestors, i);
            mod_name  = rb_mod_name(aclass);
            hit_count = rb_hash_aref(rdebug_catchpoints, mod_name);
            if (hit_count != Qnil)
            {
                debug_frame_t *top_frame = get_top_frame(debug_context);
                rb_control_frame_t *cfp = top_frame->info.runtime.cfp;

                /* save the current catch table */
                CTX_FL_SET(debug_context, CTX_FL_CATCHING);
                debug_context->catch_table.old_catch_table_size = cfp->iseq->catch_table_size;
                debug_context->catch_table.old_catch_table = cfp->iseq->catch_table;
                debug_context->catch_table.mod_name = mod_name;
                debug_context->catch_table.errinfo = rb_errinfo();

                /* create a new catch table to catch this exception, and put it in the current iseq */
                cfp->iseq->catch_table_size = 1;
                cfp->iseq->catch_table =
                    create_catch_table(debug_context, top_frame->info.runtime.last_pc - cfp->iseq->iseq_encoded - insn_len(BIN(trace)));
                break;
            }
        }

        /* If we stop the debugger, we may not be able to trace into
           code that has an exception handler wrapped around it. So
           the alternative is to force the user to do his own
           Debugger.stop. */
#ifdef NORMAL_CODE_MOVING_AFTER_
        if( !NIL_P(rb_class_inherited_p(expn_class, rb_eSystemExit)) )
        {
            debug_stop(mDebugger);
            break;
        }
#endif

        break;
    }
    }

    cleanup:
  
    debug_context->stop_reason = CTX_STOP_NONE;

    /* check that all contexts point to alive threads */
    if(hook_count - last_check > 3000)
    {
        check_thread_contexts();
        last_check = hook_count;
    }

    /* release a lock */
    locker = Qnil;

    /* let the next thread to run */
    {
        VALUE next_thread = remove_from_locked();
        if(next_thread != Qnil)
            rb_thread_run(next_thread);
    }
}

static VALUE
debug_stop_i(VALUE self)
{
    if(IS_STARTED)
        debug_stop(self);
    return Qnil;
}

/*
 *   call-seq:
 *      Debugger.start_ -> bool
 *      Debugger.start_ { ... } -> bool
 *
 *   This method is internal and activates the debugger. Use
 *   Debugger.start (from <tt>lib/ruby-debug-base.rb</tt>) instead.
 *
 *   The return value is the value of !Debugger.started? <i>before</i>
 *   issuing the +start+; That is, +true+ is returned, unless debugger
 *   was previously started.

 *   If a block is given, it starts debugger and yields to block. When
 *   the block is finished executing it stops the debugger with
 *   Debugger.stop method. Inside the block you will probably want to
 *   have a call to Debugger.debugger. For example:
 *     Debugger.start{debugger; foo}  # Stop inside of foo
 * 
 *   Also, ruby-debug only allows
 *   one invocation of debugger at a time; nested Debugger.start's
 *   have no effect and you can't use this inside the debugger itself.
 *
 *   <i>Note that if you want to completely remove the debugger hook,
 *   you must call Debugger.stop as many times as you called
 *   Debugger.start method.</i>
 */
static VALUE
debug_start(VALUE self)
{
    VALUE result;
    start_count++;

    if(IS_STARTED)
        result = Qfalse;
    else
    {
        locker             = Qnil;
        rdebug_breakpoints = rb_ary_new();
        rdebug_catchpoints = rb_hash_new();
        rdebug_threads_tbl = threads_table_create();

        rb_add_event_hook(debug_event_hook, RUBY_EVENT_ALL, Qnil);
        result = Qtrue;
    }

    if(rb_block_given_p()) 
      rb_ensure(rb_yield, self, debug_stop_i, self);

    return result;
}

/*
 *   call-seq:
 *      Debugger.stop -> bool
 *
 *   This method disables the debugger. It returns +true+ if the debugger is disabled,
 *   otherwise it returns +false+.
 *
 *   <i>Note that if you want to complete remove the debugger hook,
 *   you must call Debugger.stop as many times as you called
 *   Debugger.start method.</i>
 */
static VALUE
debug_stop(VALUE self)
{
    debug_check_started();

    start_count--;
    if(start_count)
        return Qfalse;

    rb_remove_event_hook(debug_event_hook);

    locker             = Qnil;
    rdebug_breakpoints = Qnil;
    rdebug_threads_tbl = Qnil;

    return Qtrue;
}

static int
find_last_context_func(VALUE key, VALUE value, VALUE *result)
{
    debug_context_t *debug_context;
    Data_Get_Struct(value, debug_context_t, debug_context);
    if(debug_context->thnum == last_debugged_thnum)
    {
        *result = value;
        return ST_STOP;
    }
    return ST_CONTINUE;
}

/*
 *   call-seq:
 *      Debugger.last_interrupted -> context
 *
 *   Returns last debugged context.
 */
static VALUE
debug_last_interrupted(VALUE self)
{
    VALUE result = Qnil;
    threads_table_t *threads_table;

    debug_check_started();

    Data_Get_Struct(rdebug_threads_tbl, threads_table_t, threads_table);

    st_foreach(threads_table->tbl, find_last_context_func, (st_data_t)&result);
    return result;
}

/*
 *   call-seq:
 *      Debugger.current_context -> context
 *
 *   Returns current context.
 *   <i>Note:</i> Debugger.current_context.thread == Thread.current
 */
static VALUE
debug_current_context(VALUE self)
{
    VALUE thread, context;

    debug_check_started();

    thread = rb_thread_current();
    thread_context_lookup(thread, &context, NULL, 1);

    return context;
}

/*
 *   call-seq:
 *      Debugger.thread_context(thread) -> context
 *
 *   Returns context of the thread passed as an argument.
 */
static VALUE
debug_thread_context(VALUE self, VALUE thread)
{
    VALUE context;

    debug_check_started();
    thread_context_lookup(thread, &context, NULL, 1);
    return context;
}

/*
 *   call-seq:
 *      Debugger.contexts -> array
 *
 *   Returns an array of all contexts.
 */
static VALUE
debug_contexts(VALUE self)
{
    volatile VALUE list;
    volatile VALUE new_list;
    VALUE thread, context;
    threads_table_t *threads_table;
    debug_context_t *debug_context;
    int i;

    debug_check_started();

    new_list = rb_ary_new();
    list = rb_funcall(rb_cThread, idList, 0);
    for(i = 0; i < RARRAY_LEN(list); i++)
    {
        thread = rb_ary_entry(list, i);
        thread_context_lookup(thread, &context, NULL, 1);
        rb_ary_push(new_list, context);
    }
    threads_table_clear(rdebug_threads_tbl);
    Data_Get_Struct(rdebug_threads_tbl, threads_table_t, threads_table);
    for(i = 0; i < RARRAY_LEN(new_list); i++)
    {
        context = rb_ary_entry(new_list, i);
        Data_Get_Struct(context, debug_context_t, debug_context);
        st_insert(threads_table->tbl, debug_context->thread_id, context);
    }

    return new_list;
}

/*
 *   call-seq:
 *      Debugger.suspend -> Debugger
 *
 *   Suspends all contexts.
 */
static VALUE
debug_suspend(VALUE self)
{
    VALUE current, context;
    VALUE context_list;
    debug_context_t *debug_context;
    int i;

    debug_check_started();

    context_list = debug_contexts(self);
    thread_context_lookup(rb_thread_current(), &current, NULL, 1);

    for(i = 0; i < RARRAY_LEN(context_list); i++)
    {
        context = rb_ary_entry(context_list, i);
        if(current == context)
            continue;
        Data_Get_Struct(context, debug_context_t, debug_context);
        context_suspend_0(debug_context);
    }

    return self;
}

/*
 *   call-seq:
 *      Debugger.resume -> Debugger
 *
 *   Resumes all contexts.
 */
static VALUE
debug_resume(VALUE self)
{
    VALUE current, context;
    VALUE context_list;
    debug_context_t *debug_context;
    int i;

    debug_check_started();

    context_list = debug_contexts(self);

    thread_context_lookup(rb_thread_current(), &current, NULL, 1);
    for(i = 0; i < RARRAY_LEN(context_list); i++)
    {
        context = rb_ary_entry(context_list, i);
        if(current == context)
            continue;
        Data_Get_Struct(context, debug_context_t, debug_context);
        context_resume_0(debug_context);
    }

    rb_thread_schedule();

    return self;
}

/*
 *   call-seq:
 *      Debugger.tracing -> bool
 *
 *   Returns +true+ if the global tracing is activated.
 */
static VALUE
debug_tracing(VALUE self)
{
    return tracing;
}

/*
 *   call-seq:
 *      Debugger.tracing = bool
 *
 *   Sets the global tracing flag.
 */
static VALUE
debug_set_tracing(VALUE self, VALUE value)
{
    tracing = RTEST(value) ? Qtrue : Qfalse;
    return value;
}

/*
 *   call-seq:
 *      Debugger.post_mortem? -> bool
 *
 *   Returns +true+ if post-moterm debugging is enabled.
 */
static VALUE
debug_post_mortem(VALUE self)
{
    return post_mortem;
}

/*
 *   call-seq:
 *      Debugger.post_mortem = bool
 *
 *   Sets post-moterm flag.
 *   FOR INTERNAL USE ONLY.
 */
static VALUE
debug_set_post_mortem(VALUE self, VALUE value)
{
    debug_check_started();

    post_mortem = RTEST(value) ? Qtrue : Qfalse;
    return value;
}

/*
 *   call-seq:
 *      Debugger.track_fame_args? -> bool
 *
 *   Returns +true+ if the debugger track frame argument values on calls.
 */
static VALUE
debug_track_frame_args(VALUE self)
{
    return track_frame_args;
}

/*
 *   call-seq:
 *      Debugger.track_frame_args = bool
 *
 *   Setting to +true+ will make the debugger save argument info on calls.
 */
static VALUE
debug_set_track_frame_args(VALUE self, VALUE value)
{
    track_frame_args = RTEST(value) ? Qtrue : Qfalse;
    return value;
}

/*
 *   call-seq:
 *      Debugger.keep_frame_binding? -> bool
 *
 *   Returns +true+ if the debugger will collect frame bindings.
 */
static VALUE
debug_keep_frame_binding(VALUE self)
{
    return keep_frame_binding;
}

/*
 *   call-seq:
 *      Debugger.keep_frame_binding = bool
 *
 *   Setting to +true+ will make the debugger create frame bindings.
 */
static VALUE
debug_set_keep_frame_binding(VALUE self, VALUE value)
{
    keep_frame_binding = RTEST(value) ? Qtrue : Qfalse;
    return value;
}

/* :nodoc: */
static VALUE
debug_debug(VALUE self)
{
    return debug;
}

/* :nodoc: */
static VALUE
debug_set_debug(VALUE self, VALUE value)
{
    debug = RTEST(value) ? Qtrue : Qfalse;
    return value;
}

/* :nodoc: */
static VALUE
debug_thread_inherited(VALUE klass)
{
    rb_raise(rb_eRuntimeError, "Can't inherit Debugger::DebugThread class");
}

/*
 *   call-seq:
 *      Debugger.debug_load(file, stop = false, increment_start = false) -> nil
 *
 *   Same as Kernel#load but resets current context's frames.
 *   +stop+ parameter forces the debugger to stop at the first line of code in the +file+
 *   +increment_start+ determines if start_count should be incremented. When
 *    control threads are used, they have to be set up before loading the
 *    debugger; so here +increment_start+ will be false.    
 *   FOR INTERNAL USE ONLY.
 */
static VALUE
debug_debug_load(int argc, VALUE *argv, VALUE self)
{
    VALUE file, stop, context, increment_start;
    debug_context_t *debug_context;
    int state = 0;
    
    if(rb_scan_args(argc, argv, "12", &file, &stop, &increment_start) == 1) 
    {
        stop = Qfalse;
        increment_start = Qtrue;
    }

    debug_start(self);
    if (Qfalse == increment_start) start_count--;
    
    context = debug_current_context(self);
    Data_Get_Struct(context, debug_context_t, debug_context);
    debug_context->stack_size = 0;
    if(RTEST(stop))
        debug_context->stop_next = 1;
    /* Initializing $0 to the script's path */
    ruby_script(RSTRING_PTR(file));
    rb_load_protect(file, 0, &state);
    if (0 != state) 
    {
        VALUE errinfo = rb_errinfo();
        debug_suspend(self);
        reset_stepping_stop_points(debug_context);
        rb_set_errinfo(Qnil);
        return errinfo;
    }

    /* We should run all at_exit handler's in order to provide, 
     * for instance, a chance to run all defined test cases */
    rb_exec_end_proc();

    /* We could have issued a Debugger.stop inside the debug
       session. */
    if (start_count > 0)
        debug_stop(self);

    return Qnil;
}

static VALUE
set_current_skipped_status(VALUE status)
{
    VALUE context;
    debug_context_t *debug_context;

    context = debug_current_context(Qnil);
    Data_Get_Struct(context, debug_context_t, debug_context);
    if(status)
        CTX_FL_SET(debug_context, CTX_FL_SKIPPED);
    else
        CTX_FL_UNSET(debug_context, CTX_FL_SKIPPED);
    return Qnil;
}

/*
 *   call-seq:
 *      Debugger.skip { block } -> obj or nil
 *
 *   The code inside of the block is escaped from the debugger.
 */
static VALUE
debug_skip(VALUE self)
{
    if (!rb_block_given_p()) {
        rb_raise(rb_eArgError, "called without a block");
    }
    if(!IS_STARTED)
        return rb_yield(Qnil);
    set_current_skipped_status(Qtrue);
    return rb_ensure(rb_yield, Qnil, set_current_skipped_status, Qfalse);
}

static VALUE
debug_at_exit_c(VALUE proc)
{
    return rb_funcall(proc, rb_intern("call"), 0);
}

static void
debug_at_exit_i(VALUE proc)
{
    if(!IS_STARTED)
    {
        debug_at_exit_c(proc);
    }
    else
    {
        set_current_skipped_status(Qtrue);
        rb_ensure(debug_at_exit_c, proc, set_current_skipped_status, Qfalse);
    }
}

/*
 *   call-seq:
 *      Debugger.debug_at_exit { block } -> proc
 *
 *   Register <tt>at_exit</tt> hook which is escaped from the debugger.
 *   FOR INTERNAL USE ONLY.
 */
static VALUE
debug_at_exit(VALUE self)
{
    VALUE proc;
    if (!rb_block_given_p())
        rb_raise(rb_eArgError, "called without a block");
    proc = rb_block_proc();
    rb_set_end_proc(debug_at_exit_i, proc);
    return proc;
}

/*
 *   call-seq:
 *      context.step(steps, force = false)
 *
 *   Stops the current context after a number of +steps+ are made.
 *   +force+ parameter (if true) ensures that the cursor moves from the current line.
 */
static VALUE
context_stop_next(int argc, VALUE *argv, VALUE self)
{
    VALUE steps, force;
    debug_context_t *debug_context;

    debug_check_started();

    rb_scan_args(argc, argv, "11", &steps, &force);
    if(FIX2INT(steps) < 0)
        rb_raise(rb_eRuntimeError, "Steps argument can't be negative.");

    Data_Get_Struct(self, debug_context_t, debug_context);
    debug_context->stop_next = FIX2INT(steps);
    if(RTEST(force))
        CTX_FL_SET(debug_context, CTX_FL_FORCE_MOVE);
    else
        CTX_FL_UNSET(debug_context, CTX_FL_FORCE_MOVE);

    return steps;
}

/*
 *   call-seq:
 *      context.step_over(steps, frame = nil, force = false)
 *
 *   Steps over a +steps+ number of times.
 *   Make step over operation on +frame+, by default the current frame.
 *   +force+ parameter (if true) ensures that the cursor moves from the current line.
 */
static VALUE
context_step_over(int argc, VALUE *argv, VALUE self)
{
    VALUE lines, frame, force;
    debug_context_t *debug_context;

    debug_check_started();
    Data_Get_Struct(self, debug_context_t, debug_context);
    if(debug_context->stack_size == 0)
        rb_raise(rb_eRuntimeError, "No frames collected.");

    rb_scan_args(argc, argv, "12", &lines, &frame, &force);
    debug_context->stop_line = FIX2INT(lines);
    CTX_FL_UNSET(debug_context, CTX_FL_STEPPED);
    if(frame == Qnil)
    {
        debug_context->dest_frame = debug_context->stack_size;
    }
    else
    {
        if(FIX2INT(frame) < 0 && FIX2INT(frame) >= debug_context->stack_size)
            rb_raise(rb_eRuntimeError, "Destination frame is out of range.");
        debug_context->dest_frame = debug_context->stack_size - FIX2INT(frame);
    }
    if(RTEST(force))
        CTX_FL_SET(debug_context, CTX_FL_FORCE_MOVE);
    else
        CTX_FL_UNSET(debug_context, CTX_FL_FORCE_MOVE);

    return Qnil;
}

/*
 *   call-seq:
 *      context.stop_frame(frame)
 *
 *   Stops when a frame with number +frame+ is activated. Implements +finish+ and +next+ commands.
 */
static VALUE
context_stop_frame(VALUE self, VALUE frame)
{
    debug_context_t *debug_context;

    debug_check_started();
    Data_Get_Struct(self, debug_context_t, debug_context);
    if(FIX2INT(frame) < 0 && FIX2INT(frame) >= debug_context->stack_size)
        rb_raise(rb_eRuntimeError, "Stop frame is out of range.");
    debug_context->stop_frame = debug_context->stack_size - FIX2INT(frame);

    return frame;
}

inline static int
check_frame_number(debug_context_t *debug_context, VALUE frame)
{
    int frame_n;

    frame_n = FIX2INT(frame);
    if(frame_n < 0 || frame_n >= debug_context->stack_size)
    rb_raise(rb_eArgError, "Invalid frame number %d, stack (0...%d)",
        frame_n, debug_context->stack_size - 1);
    return frame_n;
}

static int 
optional_frame_position(int argc, VALUE *argv) {
  unsigned int i_scanned;
  VALUE level;

  if ((argc > 1) || (argc < 0))
    rb_raise(rb_eArgError, "wrong number of arguments (%d for 0 or 1)", argc);
  i_scanned = rb_scan_args(argc, argv, "01", &level);
  if (0 == i_scanned) {
    level = INT2FIX(0);
  }
  return level;
}

/*
 *   call-seq:
 *      context.frame_args_info(frame_position=0) -> list 
        if track_frame_args or nil otherwise
 *
 *   Returns info saved about call arguments (if any saved).
 */
static VALUE
context_frame_args_info(int argc, VALUE *argv, VALUE self)
{
    VALUE frame;
    debug_context_t *debug_context;

    debug_check_started();
    frame = optional_frame_position(argc, argv);
    Data_Get_Struct(self, debug_context_t, debug_context);

    return RTEST(track_frame_args) ? GET_FRAME->arg_ary : Qnil;
}

/*
 *   call-seq:
 *      context.frame_binding(frame_position=0) -> binding
 *
 *   Returns frame's binding.
 */
static VALUE
context_frame_binding(int argc, VALUE *argv, VALUE self)
{
    VALUE frame;
    debug_context_t *debug_context;

    debug_check_started();
    frame = optional_frame_position(argc, argv);
    Data_Get_Struct(self, debug_context_t, debug_context);
    return GET_FRAME->binding;
}

/*
 *   call-seq:
 *      context.frame_method(frame_position=0) -> sym
 *
 *   Returns the sym of the called method.
 */
static VALUE
context_frame_id(int argc, VALUE *argv, VALUE self)
{
    ID id;
    VALUE frame;
    debug_context_t *debug_context;

    debug_check_started();
    frame = optional_frame_position(argc, argv);
    Data_Get_Struct(self, debug_context_t, debug_context);

    id = GET_FRAME->info.runtime.cfp->iseq->defined_method_id;
    return id ? ID2SYM(id): Qnil;
}

/*
 *   call-seq:
 *      context.frame_line(frame_position) -> int
 *
 *   Returns the line number in the file.
 */
static VALUE
context_frame_line(int argc, VALUE *argv, VALUE self)
{
    VALUE frame;
    debug_context_t *debug_context;
    rb_thread_t *th;
    rb_control_frame_t *cfp;
    VALUE *pc;

    debug_check_started();
    frame = optional_frame_position(argc, argv);
    Data_Get_Struct(self, debug_context_t, debug_context);
    GetThreadPtr(context_thread_0(debug_context), th);

    pc = GET_FRAME->info.runtime.last_pc;
    cfp = GET_FRAME->info.runtime.cfp;
    while (cfp >= th->cfp)
    {
        if ((cfp->iseq != NULL) && (pc >= cfp->iseq->iseq_encoded) && (pc < cfp->iseq->iseq_encoded + cfp->iseq->iseq_size))
            return(INT2FIX(rb_vm_get_sourceline(cfp)));
        cfp = RUBY_VM_NEXT_CONTROL_FRAME(cfp);
    }

    return(INT2FIX(0));
}

/*
 *   call-seq:
 *      context.frame_file(frame_position) -> string
 *
 *   Returns the name of the file.
 */
static VALUE
context_frame_file(int argc, VALUE *argv, VALUE self)
{
    VALUE frame;
    debug_context_t *debug_context;

    debug_check_started();
    frame = optional_frame_position(argc, argv);
    Data_Get_Struct(self, debug_context_t, debug_context);

    return(GET_FRAME->info.runtime.cfp->iseq->filename);
}

static int
arg_value_is_small(VALUE val) 
{
  switch (TYPE(val)) {
  case T_FIXNUM: case T_FLOAT:  case T_CLASS:
  case T_NIL:    case T_MODULE: case T_FILE:
  case T_TRUE:   case T_FALSE:  case T_UNDEF:
    return 1;
  default:
    return SYMBOL_P(val);
  }
}

/*
 *   Save scalar arguments or a class name.
 */
static void
copy_scalar_args(debug_frame_t *debug_frame)
{
    rb_control_frame_t *cfp;
    rb_iseq_t *iseq;

    cfp = debug_frame->info.runtime.cfp;
    iseq = cfp->iseq;

    if (iseq->local_table && iseq->argc)
    {
        int i;
        VALUE val;

        debug_frame->arg_ary = rb_ary_new2(iseq->argc);
        for (i = 0; i < iseq->argc; i++)
        {
            if (!rb_is_local_id(iseq->local_table[i])) continue; /* skip flip states */

            val = *(cfp->dfp - iseq->local_size + i);

            if (arg_value_is_small(val))
                rb_ary_push(debug_frame->arg_ary, val);
            else
                rb_ary_push(debug_frame->arg_ary, rb_str_new2(rb_obj_classname(val)));
        }
    }
}

/*
 *   call-seq:
 *      context.copy_args(frame) -> list of args
 *
 *   Returns a array of argument names.
 */
static VALUE
context_copy_args(debug_frame_t *debug_frame)
{
    rb_control_frame_t *cfp;
    rb_iseq_t *iseq;

    cfp = debug_frame->info.runtime.cfp;
    iseq = cfp->iseq;

    if (iseq->local_table && iseq->argc)
    {
        int i;
        VALUE list;

        list = rb_ary_new2(iseq->argc);
        for (i = 0; i < iseq->argc; i++)
        {
            if (!rb_is_local_id(iseq->local_table[i])) continue; /* skip flip states */
            rb_ary_push(list, rb_id2str(iseq->local_table[i]));
        }

        return(list);
    }
    return(rb_ary_new2(0));
}

static VALUE
context_copy_locals(debug_context_t *debug_context, debug_frame_t *debug_frame, VALUE self)
{
    int i;
    rb_control_frame_t *cfp;
    rb_iseq_t *iseq;
    VALUE hash;

    cfp = debug_frame->info.runtime.cfp;
    iseq = cfp->iseq;
    hash = rb_hash_new();

    if (iseq->local_table != NULL)
    {
        /* Note rb_iseq_disasm() is instructive in coming up with this code */
        for (i = 0; i < iseq->local_table_size; i++)
        {
            VALUE str = rb_id2str(iseq->local_table[i]);
            if (str != 0)
                rb_hash_aset(hash, str, *(cfp->dfp - iseq->local_size + i));
        }
    }

    iseq = cfp->block_iseq;
    if ((iseq != NULL) && (iseq->local_table != NULL) && (iseq != cfp->iseq))
    {
        rb_thread_t *th;
        rb_control_frame_t *block_frame = RUBY_VM_NEXT_CONTROL_FRAME(cfp);
        GetThreadPtr(context_thread_0(debug_context), th);
        while (block_frame > (rb_control_frame_t*)th->stack)
        {
            if (block_frame->iseq == cfp->block_iseq)
            {
                for (i = 0; i < iseq->local_table_size; i++)
                {
                    VALUE str = rb_id2str(iseq->local_table[i]);
                    if (str != 0)
                        rb_hash_aset(hash, str, *(block_frame->dfp - iseq->local_table_size + i - 1));
                }
                return(hash);
            }
            block_frame = RUBY_VM_NEXT_CONTROL_FRAME(block_frame);
        } 
    }

    return(hash);
}

/*
 *   call-seq:
 *      context.frame_locals(frame) -> hash
 *
 *   Returns frame's local variables.
 */
static VALUE
context_frame_locals(int argc, VALUE *argv, VALUE self)
{
    VALUE frame;
    debug_context_t *debug_context;
    debug_frame_t *debug_frame;
    
    debug_check_started();
    frame = optional_frame_position(argc, argv);
    Data_Get_Struct(self, debug_context_t, debug_context);

    debug_frame = GET_FRAME;
    if (debug_frame->dead)
        return debug_frame->info.copy.locals;
    else
        return context_copy_locals(debug_context, debug_frame, self);
}

/*
 *   call-seq:
 *      context.frame_args(frame_position=0) -> list
 *
 *   Returns frame's argument parameters
 */
static VALUE
context_frame_args(int argc, VALUE *argv, VALUE self)
{
    VALUE frame;
    debug_context_t *debug_context;
    debug_frame_t *debug_frame;

    debug_check_started();
    frame = optional_frame_position(argc, argv);
    Data_Get_Struct(self, debug_context_t, debug_context);

    debug_frame = GET_FRAME;
    if (debug_frame->dead)
        return debug_frame->info.copy.args;
    else
        return context_copy_args(debug_frame);
}

/*
 *   call-seq:
 *      context.frame_self(frame_postion=0) -> obj
 *
 *   Returns self object of the frame.
 */
static VALUE
context_frame_self(int argc, VALUE *argv, VALUE self)
{
    VALUE frame;
    debug_context_t *debug_context;
    debug_frame_t *debug_frame;
    
    debug_check_started();
    frame = optional_frame_position(argc, argv);
    Data_Get_Struct(self, debug_context_t, debug_context);

    debug_frame = GET_FRAME;
    return(debug_frame->self);
}

/*
 *   call-seq:
 *      context.frame_class(frame_position) -> obj
 *
 *   Returns the real class of the frame. 
 *   It could be different than context.frame_self(frame).class
 */
static VALUE
context_frame_class(int argc, VALUE *argv, VALUE self)
{
    VALUE klass;
    VALUE frame;
    debug_context_t *debug_context;
    debug_frame_t *debug_frame;
    rb_control_frame_t *cfp;
    
    debug_check_started();
    frame = optional_frame_position(argc, argv);
    Data_Get_Struct(self, debug_context_t, debug_context);

    debug_frame = GET_FRAME;

    cfp = debug_frame->info.runtime.cfp;

    klass = real_class(cfp->iseq->klass);
    if(TYPE(klass) == T_CLASS || TYPE(klass) == T_MODULE)
        return klass;
    return Qnil;
}


/*
 *   call-seq:
 *      context.stack_size-> int
 *
 *   Returns the size of the context stack.
 */
static VALUE
context_stack_size(VALUE self)
{
    debug_context_t *debug_context;

    debug_check_started();
    Data_Get_Struct(self, debug_context_t, debug_context);

    return INT2FIX(debug_context->stack_size);
}

/*
 *   call-seq:
 *      context.thread -> thread
 *
 *   Returns a thread this context is associated with.
 */
static VALUE
context_thread(VALUE self)
{
    debug_context_t *debug_context;

    debug_check_started();
    Data_Get_Struct(self, debug_context_t, debug_context);

    return(id2ref(debug_context->thread_id));
}

/*
 *   call-seq:
 *      context.thnum -> int
 *
 *   Returns the context's number.
 */
static VALUE
context_thnum(VALUE self)
{
    debug_context_t *debug_context;

    debug_check_started();
    Data_Get_Struct(self, debug_context_t, debug_context);
    
    return INT2FIX(debug_context->thnum);
}

static void
context_suspend_0(debug_context_t *debug_context)
{
    VALUE status;

    status = rb_funcall(context_thread_0(debug_context), rb_intern("status"), 0);
    if(rb_str_cmp(status, rb_str_new2("run")) == 0)
      CTX_FL_SET(debug_context, CTX_FL_WAS_RUNNING);
    else if(rb_str_cmp(status, rb_str_new2("sleep")) == 0)
      CTX_FL_UNSET(debug_context, CTX_FL_WAS_RUNNING);
    else
      return;
    CTX_FL_SET(debug_context, CTX_FL_SUSPEND);
}

static void
context_resume_0(debug_context_t *debug_context)
{
    if(!CTX_FL_TEST(debug_context, CTX_FL_SUSPEND))
      return;
    CTX_FL_UNSET(debug_context, CTX_FL_SUSPEND);
    if(CTX_FL_TEST(debug_context, CTX_FL_WAS_RUNNING))
      rb_thread_wakeup(context_thread_0(debug_context));
}

/*
 *   call-seq:
 *      context.suspend -> nil
 *
 *   Suspends the thread when it is running.
 */
static VALUE
context_suspend(VALUE self)
{
    debug_context_t *debug_context;

    debug_check_started();

    Data_Get_Struct(self, debug_context_t, debug_context);
    if(CTX_FL_TEST(debug_context, CTX_FL_SUSPEND))
        rb_raise(rb_eRuntimeError, "Already suspended.");
    context_suspend_0(debug_context);
    return Qnil;
}

/*
 *   call-seq:
 *      context.suspended? -> bool
 *
 *   Returns +true+ if the thread is suspended by debugger.
 */
static VALUE
context_is_suspended(VALUE self)
{
    debug_context_t *debug_context;

    debug_check_started();

    Data_Get_Struct(self, debug_context_t, debug_context);
    return CTX_FL_TEST(debug_context, CTX_FL_SUSPEND) ? Qtrue : Qfalse;
}

/*
 *   call-seq:
 *      context.resume -> nil
 *
 *   Resumes the thread from the suspended mode.
 */
static VALUE
context_resume(VALUE self)
{
    debug_context_t *debug_context;

    debug_check_started();

    Data_Get_Struct(self, debug_context_t, debug_context);
    if(!CTX_FL_TEST(debug_context, CTX_FL_SUSPEND))
        rb_raise(rb_eRuntimeError, "Thread is not suspended.");
    context_resume_0(debug_context);
    return Qnil;
}

/*
 *   call-seq:
 *      context.tracing -> bool
 *
 *   Returns the tracing flag for the current context.
 */
static VALUE
context_tracing(VALUE self)
{
    debug_context_t *debug_context;

    debug_check_started();

    Data_Get_Struct(self, debug_context_t, debug_context);
    return CTX_FL_TEST(debug_context, CTX_FL_TRACING) ? Qtrue : Qfalse;
}

/*
 *   call-seq:
 *      context.tracing = bool
 *
 *   Controls the tracing for this context.
 */
static VALUE
context_set_tracing(VALUE self, VALUE value)
{
    debug_context_t *debug_context;

    debug_check_started();

    Data_Get_Struct(self, debug_context_t, debug_context);
    if(RTEST(value))
        CTX_FL_SET(debug_context, CTX_FL_TRACING);
    else
        CTX_FL_UNSET(debug_context, CTX_FL_TRACING);
    return value;
}

/*
 *   call-seq:
 *      context.ignored? -> bool
 *
 *   Returns the ignore flag for the current context.
 */
static VALUE
context_ignored(VALUE self)
{
    debug_context_t *debug_context;

    debug_check_started();

    Data_Get_Struct(self, debug_context_t, debug_context);
    return CTX_FL_TEST(debug_context, CTX_FL_IGNORE) ? Qtrue : Qfalse;
}

/*
 *   call-seq:
 *      context.dead? -> bool
 *
 *   Returns +true+ if context doesn't represent a live context and is created
 *   during post-mortem exception handling.
 */
static VALUE
context_dead(VALUE self)
{
    debug_context_t *debug_context;

    debug_check_started();

    Data_Get_Struct(self, debug_context_t, debug_context);
    return CTX_FL_TEST(debug_context, CTX_FL_DEAD) ? Qtrue : Qfalse;
}

/*
 *   call-seq:
 *      context.stop_reason -> sym
 *   
 *   Returns the reason for the stop. It maybe of the following values:
 *   :initial, :step, :breakpoint, :catchpoint, :post-mortem
 */
static VALUE
context_stop_reason(VALUE self)
{
    debug_context_t *debug_context;
    const char * sym_name;

    debug_check_started();

    Data_Get_Struct(self, debug_context_t, debug_context);
    
    switch(debug_context->stop_reason)
    {
        case CTX_STOP_STEP:
            sym_name = "step";
            break;
        case CTX_STOP_BREAKPOINT:
            sym_name = "breakpoint";
            break;
        case CTX_STOP_CATCHPOINT:
            sym_name = "catchpoint";
            break;
        case CTX_STOP_NONE:
        default:
            sym_name = "none";
    }
    if(CTX_FL_TEST(debug_context, CTX_FL_DEAD))
        sym_name = "post-mortem";
    
    return ID2SYM(rb_intern(sym_name));
}

static rb_control_frame_t *
FUNC_FASTCALL(do_jump)(rb_thread_t *th, rb_control_frame_t *cfp)
{
    VALUE context;
    debug_context_t *debug_context;
    rb_control_frame_t *jump_cfp;
    VALUE *jump_pc;

    thread_context_lookup(th->self, &context, &debug_context, 0);
    if (debug_context == NULL)
        rb_raise(rb_eRuntimeError, "Lost context in jump");
    cfp->pc[-2] = debug_context->saved_jump_ins[0];
    cfp->pc[-1] = debug_context->saved_jump_ins[1];

    if ((debug_context->jump_pc < debug_context->jump_cfp->iseq->iseq_encoded) || 
        (debug_context->jump_pc >= debug_context->jump_cfp->iseq->iseq_encoded + debug_context->jump_cfp->iseq->iseq_size))
        rb_raise(rb_eRuntimeError, "Invalid jump PC target");

    jump_cfp = debug_context->jump_cfp;
    jump_pc = debug_context->jump_pc;
    debug_context->jump_pc = NULL;
    debug_context->jump_cfp = NULL;
    debug_context->last_line = 0;
    debug_context->last_file = NULL;
    debug_context->stop_next = 1;

    if (cfp < jump_cfp)
    {
        /* save all intermediate-frame catch tables
           +1 for target frame
           +1 for array terminator
         */
        int frames = jump_cfp - cfp + 2;
        debug_context->old_iseq_catch = (iseq_catch_t*)malloc(frames * sizeof(iseq_catch_t));
        MEMZERO(debug_context->old_iseq_catch, iseq_catch_t, frames);
        frames = 0;
        do
        {
            if (cfp->iseq != NULL)
            {
                debug_context->old_iseq_catch[frames].iseq = cfp->iseq;
                debug_context->old_iseq_catch[frames].catch_table = cfp->iseq->catch_table;
                debug_context->old_iseq_catch[frames].catch_table_size = cfp->iseq->catch_table_size;
                cfp->iseq->catch_table = NULL;
                cfp->iseq->catch_table_size = 0;

                frames++;
            }
            cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(cfp);
        } while (cfp <= jump_cfp);

        jump_cfp->iseq->catch_table_size = 1;
        jump_cfp->iseq->catch_table = 
            create_catch_table(debug_context, jump_pc - jump_cfp->iseq->iseq_encoded);
        jump_cfp->iseq->catch_table->sp = -1;

        JUMP_TAG(TAG_RAISE);
    }
    else if (cfp > jump_cfp)
        rb_raise(rb_eRuntimeError, "Invalid jump frame target");

    cfp->pc = jump_pc;
    return(cfp);
}

/*
 *   call-seq:
 *      context.jump(line, file) -> bool
 *
 *   Returns +true+ if jump to +line+ in filename +file+ was successful.
 */
static VALUE
context_jump(VALUE self, VALUE line, VALUE file)
{
    debug_context_t *debug_context;
    debug_frame_t *debug_frame;
    int i;
    rb_thread_t *th;
    rb_control_frame_t *cfp;
    rb_control_frame_t *cfp_end;
    rb_control_frame_t *cfp_start = NULL;

    debug_check_started();

    Data_Get_Struct(self, debug_context_t, debug_context);
    GetThreadPtr(context_thread_0(debug_context), th);
    debug_frame = get_top_frame(debug_context);
    if (debug_frame == NULL)
        rb_raise(rb_eRuntimeError, "No frames collected.");

    line = FIX2INT(line);

    /* find topmost frame of the debugged code */
    cfp = th->cfp;
    cfp_end = RUBY_VM_END_CONTROL_FRAME(th);
    while (RUBY_VM_VALID_CONTROL_FRAME_P(cfp, cfp_end))
    {
        if (cfp->pc == debug_frame->info.runtime.last_pc)
        {
            cfp_start = cfp;
            if ((cfp->pc - cfp->iseq->iseq_encoded) >= (cfp->iseq->iseq_size - 1))
                return(INT2FIX(1)); /* no space for opt_call_c_function hijack */
            break;
        }
        cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(cfp);
    }
    if (cfp_start == NULL)
        return(INT2FIX(2)); /* couldn't find frame; should never happen */

    /* find target frame to jump to */
    while (RUBY_VM_VALID_CONTROL_FRAME_P(cfp, cfp_end))
    {
        if ((cfp->iseq != NULL) && (rb_str_cmp(file, cfp->iseq->filename) == 0))
        {
            for (i = 0; i < cfp->iseq->insn_info_size; i++)
            {
                if (cfp->iseq->insn_info_table[i].line_no != line)
                    continue;

                /* hijack the currently running code so that we can change the frame PC */
                debug_context->saved_jump_ins[0] = cfp_start->pc[0];
                debug_context->saved_jump_ins[1] = cfp_start->pc[1];
                cfp_start->pc[0] = opt_call_c_function;
                cfp_start->pc[1] = (VALUE)do_jump;

                debug_context->jump_cfp = cfp;
                debug_context->jump_pc =
                    cfp->iseq->iseq_encoded + cfp->iseq->insn_info_table[i].position;

                return(INT2FIX(0)); /* success */
            }
        }

        cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(cfp);
    }

    return(INT2FIX(3)); /* couldn't find a line and file frame match */
}

/*
 *   call-seq:
 *      context.break -> bool
 *
 *   Returns +true+ if context is currently running and set flag to break it at next line
 */
static VALUE
context_pause(VALUE self)
{
    debug_context_t *debug_context;
    rb_thread_t *th;

    debug_check_started();

    Data_Get_Struct(self, debug_context_t, debug_context);
    if (CTX_FL_TEST(debug_context, CTX_FL_DEAD))
        return(Qfalse);

    GetThreadPtr(context_thread_0(debug_context), th);
    if (th == GET_THREAD())
        return(Qfalse);

    debug_context->thread_pause = 1;
    return(Qtrue);
}

/*
 *   Document-class: Context
 *
 *   == Summary
 *
 *   Debugger keeps a single instance of this class for each Ruby thread.
 */
static void
Init_context()
{
    cContext = rb_define_class_under(mDebugger, "Context", rb_cObject);
    rb_define_method(cContext, "stop_next=", context_stop_next, -1);
    rb_define_method(cContext, "step", context_stop_next, -1);
    rb_define_method(cContext, "step_over", context_step_over, -1);
    rb_define_method(cContext, "stop_frame=", context_stop_frame, 1);
    rb_define_method(cContext, "thread", context_thread, 0);
    rb_define_method(cContext, "thnum", context_thnum, 0);
    rb_define_method(cContext, "stop_reason", context_stop_reason, 0);
    rb_define_method(cContext, "suspend", context_suspend, 0);
    rb_define_method(cContext, "suspended?", context_is_suspended, 0);
    rb_define_method(cContext, "resume", context_resume, 0);
    rb_define_method(cContext, "tracing", context_tracing, 0);
    rb_define_method(cContext, "tracing=", context_set_tracing, 1);
    rb_define_method(cContext, "ignored?", context_ignored, 0);
    rb_define_method(cContext, "frame_args", context_frame_args, -1);
    rb_define_method(cContext, "frame_args_info", context_frame_args_info, -1);
    rb_define_method(cContext, "frame_binding", context_frame_binding, -1);
    rb_define_method(cContext, "frame_class", context_frame_class, -1);
    rb_define_method(cContext, "frame_file", context_frame_file, -1);
    rb_define_method(cContext, "frame_id", context_frame_id, -1);
    rb_define_method(cContext, "frame_line", context_frame_line, -1);
    rb_define_method(cContext, "frame_locals", context_frame_locals, -1);
    rb_define_method(cContext, "frame_method", context_frame_id, -1);
    rb_define_method(cContext, "frame_self", context_frame_self, -1);
    rb_define_method(cContext, "stack_size", context_stack_size, 0);
    rb_define_method(cContext, "dead?", context_dead, 0);
    rb_define_method(cContext, "breakpoint", 
             context_breakpoint, 0);      /* in breakpoint.c */
    rb_define_method(cContext, "set_breakpoint", 
             context_set_breakpoint, -1); /* in breakpoint.c */
    rb_define_method(cContext, "jump", context_jump, 2);
    rb_define_method(cContext, "pause", context_pause, 0);
}

/*
 *   call-seq:
 *      Debugger.breakpoints -> array
 *
 *   Returns an array of breakpoints.
 */
static VALUE
debug_breakpoints(VALUE self)
{
    debug_check_started();

    return rdebug_breakpoints;
}

/*
 *   call-seq:
 *      Debugger.add_breakpoint(source, pos, condition = nil) -> breakpoint
 *
 *   Adds a new breakpoint.
 *   <i>source</i> is a name of a file or a class.
 *   <i>pos</i> is a line number or a method name if <i>source</i> is a class name.
 *   <i>condition</i> is a string which is evaluated to +true+ when this breakpoint
 *   is activated.
 */
static VALUE
debug_add_breakpoint(int argc, VALUE *argv, VALUE self)
{
    VALUE result;

    debug_check_started();

    result = create_breakpoint_from_args(argc, argv, ++bkp_count);
    rb_ary_push(rdebug_breakpoints, result);
    return result;
}

/*
 *   Document-class: Debugger
 *
 *   == Summary
 *
 *   This is a singleton class allows controlling the debugger. Use it to start/stop debugger,
 *   set/remove breakpoints, etc.
 */
void
Init_ruby_debug()
{
    rb_iseq_t iseq;
    iseq.iseq = &opt_call_c_function;
    iseq.iseq_size = 1;
    iseq.iseq_encoded = NULL;

    opt_call_c_function = (VALUE)BIN(opt_call_c_function);
    rb_iseq_translate_threaded_code(&iseq);
    if (iseq.iseq_encoded != iseq.iseq)
    {
        opt_call_c_function = iseq.iseq_encoded[0];
        xfree(iseq.iseq_encoded);
    }

    mDebugger = rb_define_module("Debugger");
    rb_define_const(mDebugger, "VERSION", rb_str_new2(DEBUG_VERSION));
    rb_define_module_function(mDebugger, "start_", debug_start, 0);
    rb_define_module_function(mDebugger, "stop", debug_stop, 0);
    rb_define_module_function(mDebugger, "started?", debug_is_started, 0);
    rb_define_module_function(mDebugger, "breakpoints", debug_breakpoints, 0);
    rb_define_module_function(mDebugger, "add_breakpoint", debug_add_breakpoint, -1);
    rb_define_module_function(mDebugger, "remove_breakpoint", 
                  rdebug_remove_breakpoint, 
                  1);                        /* in breakpoint.c */
    rb_define_module_function(mDebugger, "add_catchpoint", 
                  rdebug_add_catchpoint, 1); /* in breakpoint.c */
    rb_define_module_function(mDebugger, "catchpoints", 
                  debug_catchpoints, 0);     /* in breakpoint.c */
    rb_define_module_function(mDebugger, "last_context", debug_last_interrupted, 0);
    rb_define_module_function(mDebugger, "contexts", debug_contexts, 0);
    rb_define_module_function(mDebugger, "current_context", debug_current_context, 0);
    rb_define_module_function(mDebugger, "thread_context", debug_thread_context, 1);
    rb_define_module_function(mDebugger, "suspend", debug_suspend, 0);
    rb_define_module_function(mDebugger, "resume", debug_resume, 0);
    rb_define_module_function(mDebugger, "tracing", debug_tracing, 0);
    rb_define_module_function(mDebugger, "tracing=", debug_set_tracing, 1);
    rb_define_module_function(mDebugger, "debug_load", debug_debug_load, -1);
    rb_define_module_function(mDebugger, "skip", debug_skip, 0);
    rb_define_module_function(mDebugger, "debug_at_exit", debug_at_exit, 0);
    rb_define_module_function(mDebugger, "post_mortem?", debug_post_mortem, 0);
    rb_define_module_function(mDebugger, "post_mortem=", debug_set_post_mortem, 1);
    rb_define_module_function(mDebugger, "keep_frame_binding?", 
                  debug_keep_frame_binding, 0);
    rb_define_module_function(mDebugger, "keep_frame_binding=", 
                  debug_set_keep_frame_binding, 1);
    rb_define_module_function(mDebugger, "track_frame_args?", 
                  debug_track_frame_args, 0);
    rb_define_module_function(mDebugger, "track_frame_args=", 
                  debug_set_track_frame_args, 1);
    rb_define_module_function(mDebugger, "debug", debug_debug, 0);
    rb_define_module_function(mDebugger, "debug=", debug_set_debug, 1);

    cThreadsTable = rb_define_class_under(mDebugger, "ThreadsTable", rb_cObject);

    cDebugThread  = rb_define_class_under(mDebugger, "DebugThread", rb_cThread);
    rb_define_singleton_method(cDebugThread, "inherited", 
                   debug_thread_inherited, 1);

    Init_context();
    Init_breakpoint();

    idAtBreakpoint = rb_intern("at_breakpoint");
    idAtCatchpoint = rb_intern("at_catchpoint");
    idAtLine       = rb_intern("at_line");
    idAtReturn     = rb_intern("at_return");
    idAtTracing    = rb_intern("at_tracing");
    idList         = rb_intern("list");

    rb_mObjectSpace = rb_const_get(rb_mKernel, rb_intern("ObjectSpace"));

    rb_global_variable(&last_context);
    rb_global_variable(&last_thread);
    rb_global_variable(&locker);
    rb_global_variable(&rdebug_breakpoints);
    rb_global_variable(&rdebug_catchpoints);
    rb_global_variable(&rdebug_threads_tbl);
}
