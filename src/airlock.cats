#ifndef ANTHRACITE_AIRLOCK_CATS
#define ANTHRACITE_AIRLOCK_CATS

#include <stdio.h>
#include <stdlib.h>

/* Runtime half of the airlock: the static claim (nat) is only trusted
   because this check runs first. A violation is a program bug, so fail fast. */
static inline int anth_airlock_nat(int n)
{
  if (n < 0) {
    fprintf(stderr, "event=airlock_nat status=failed value=%d\n", n);
    abort();
  }
  return n;
}

static inline int anth_airlock_pos(int n)
{
  if (n < 1) {
    fprintf(stderr, "event=airlock_pos status=failed value=%d\n", n);
    abort();
  }
  return n;
}

static inline int anth_airlock_below(int i, int cap)
{
  if (i < 0 || i >= cap) {
    fprintf(stderr, "event=airlock_below status=failed i=%d cap=%d\n", i, cap);
    abort();
  }
  return i;
}

static inline int anth_airlock_word(int i, int cap)
{
  if (i < 0 || cap < 4 || i > (cap - 4) / 4) {
    fprintf(stderr, "event=airlock_word status=failed i=%d cap=%d\n", i, cap);
    abort();
  }
  return i;
}

static inline int anth_airlock_span(int lo, int hi)
{
  if (lo > hi) {
    fprintf(stderr, "event=airlock_span status=failed lo=%d hi=%d\n", lo, hi);
    abort();
  }
  return hi - lo;
}

static inline int anth_die_msg(void)
{
  fprintf(stderr, "event=recursion_fuel status=failed\n");
  abort();
  return 0;
}

#define anth_die_void(...) (anth_die_msg())
#define anth_die_int(...) (anth_die_msg())
#define anth_die_bool(...) (anth_die_msg(), 0)
#define anth_die_dbl(...) (anth_die_msg(), 0.0)
#define anth_die_box(...) (anth_die_msg(), (void *)0)

#endif
