#ifndef YYPSLR_LAYOUT_DEFINED
# define YYPSLR_LAYOUT_DEFINED

#include <limits.h>
#include <string.h>

typedef struct yypslr_layout {
  const char *text;
  int length;
} yypslr_layout;

# ifndef YYPSLR_LAYOUT_BUFFER_SIZE
#  define YYPSLR_LAYOUT_BUFFER_SIZE 4096
# endif

# if defined __cplusplus && 201103L <= __cplusplus
#  define YYPSLR_THREAD_LOCAL thread_local
# elif defined _MSC_VER
#  define YYPSLR_THREAD_LOCAL __declspec(thread)
# elif defined __STDC_VERSION__ && 201112L <= __STDC_VERSION__
#  define YYPSLR_THREAD_LOCAL _Thread_local
# elif defined __GNUC__ || defined __clang__
#  define YYPSLR_THREAD_LOCAL __thread
# else
#  error "PSLR requires thread-local storage"
# endif

typedef struct yypslr_scanner {
  char initial[YYPSLR_LAYOUT_BUFFER_SIZE];
  char *buffer;
  size_t capacity;
  int length;
<%- if output.pslr_pure_mode? -%>
  struct {
    const char *cursor;
    size_t remaining;
    int parser_state;
<%- if output.grammar.locations -%>
    const char *location_cursor;
    int line, column;
<%- end -%>
  } input;
<%- end -%>
} yypslr_scanner;

/* Outside yyparse, scanner helpers operate on the calling thread's input. */
static YYPSLR_THREAD_LOCAL yypslr_scanner yypslr_pending;
static YYPSLR_THREAD_LOCAL yypslr_scanner *yypslr_active;

<%- if output.pslr_pure_mode? -%>
static YYPSLR_THREAD_LOCAL int yypslr_has_input;

static void
yypslr_take_input (yypslr_scanner *scanner)
{
  scanner->input = yypslr_pending.input;
  memset (&yypslr_pending.input, 0, sizeof yypslr_pending.input);
  yypslr_has_input = 0;
}
<%- end -%>

static yypslr_scanner *
yypslr_current (void)
{
  return yypslr_active ? yypslr_active : &yypslr_pending;
}

static char *
yypslr_layout_buffer (yypslr_scanner *scanner)
{
  return scanner->buffer ? scanner->buffer : scanner->initial;
}

static void
yypslr_layout_clear (yypslr_scanner *scanner)
{
  if (scanner->buffer)
    YYFREE (scanner->buffer);
  scanner->buffer = 0;
  scanner->capacity = 0;
  scanner->length = 0;
  scanner->initial[0] = '\0';
}

static int
yypslr_layout_append (const char *text, int length)
{
  yypslr_scanner *scanner = yypslr_current ();
  char *text_buffer = yypslr_layout_buffer (scanner);
  size_t capacity = scanner->buffer ? scanner->capacity : sizeof scanner->initial;
  size_t required;
  if (length < 0 || length > INT_MAX - scanner->length)
    return 0;

  required = (size_t) scanner->length + (size_t) length + 1;
  if (required > (size_t) YYSIZE_MAXIMUM)
    return 0;
  if (required > capacity)
    {
      char *buffer;
      while (capacity < required)
        capacity = capacity > (size_t) YYSIZE_MAXIMUM / 2 ? required : capacity * 2;
      buffer = YY_CAST (char *, YYMALLOC (capacity));
      if (!buffer)
        return 0;
      memcpy (buffer, text_buffer, (size_t) scanner->length);
      if (scanner->buffer)
        YYFREE (scanner->buffer);
      text_buffer = scanner->buffer = buffer;
      scanner->capacity = capacity;
    }

  memcpy (text_buffer + scanner->length, text, (size_t) length);
  scanner->length += length;
  text_buffer[scanner->length] = '\0';
  return 1;
}

# define YYPSLR_LAYOUT_TEXT    yypslr_layout_buffer (yypslr_current ())
# define YYPSLR_LAYOUT_LENGTH  (yypslr_current ()->length)
# define YYPSLR_LAYOUT_CLEAR() yypslr_layout_clear (yypslr_current ())
# define YYPSLR_LAYOUT_APPEND(Text, Len) yypslr_layout_append ((Text), (Len))

static void
yypslr_leave (yypslr_scanner *outer)
{
<%- if output.pslr_pure_mode? -%>
  if (!outer && !yypslr_has_input)
    yypslr_pending.input = yypslr_active->input;
<%- end -%>
  YYPSLR_LAYOUT_CLEAR ();
  yypslr_active = outer;
}

typedef struct yypslr_scope {
  yypslr_scanner frame;
  yypslr_scanner *outer;
#ifdef __cplusplus
  ~yypslr_scope () { yypslr_leave (outer); }
#endif
} yypslr_scope;

static void
yypslr_enter (yypslr_scope *scope)
{
  memset (&scope->frame, 0, sizeof scope->frame);
<%- if output.pslr_pure_mode? -%>
  yypslr_take_input (&scope->frame);
<%- end -%>
  scope->outer = yypslr_active;
  yypslr_active = &scope->frame;
}

#ifdef __cplusplus
# define YYPSLR_LEAVE(Scope) ((void) 0)
#else
# define YYPSLR_LEAVE(Scope) yypslr_leave ((Scope).outer)
#endif

#endif /* YYPSLR_LAYOUT_DEFINED */
