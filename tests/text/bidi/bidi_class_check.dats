#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/source/text_source.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/unicode/property_symbols.sats"
staload "data_text/bidi/bidi_bracket_data.sats"
staload "text/bidi/bidi_fixture.sats"
staload "text/bidi/bidi_class_fixture.sats"
extern fun class_fixture_exhausted(): int = "mac#anth_die_int"
staload "data_text/bidi/bidi_resolution.sats"
staload "data_text/bidi/bidi_line.sats"

implement bidi_class_test(source,start,finish,brackets,direction,expected) = let
  val+ ~BidiClassFixture(text,work) = bidi_class_fixture(source,start,finish)
  val base = bidi_resolve(work,text,brackets,direction)
  val () = bidi_line_reset(work,0,bidi_count(work),base)
  val order = bidi_line_order(work,0,bidi_count(work))
  val levels = bidi_fixture_check_levels(source,expected.level_start,expected.level_end,work)
  val indices = bidi_fixture_check_order(source,expected.order_start,expected.order_end,order)
  val () = bidi_order_dispose(order)
  val () = bidi_dispose(work)
  val () = scalar_dispose(text)
in iadd(levels,indices) end
