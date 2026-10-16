#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "text/arabic/joining/arabic_join_contracts.sats"
fun forward(k: ArabicJoining): bool = case+ k of
  | JoinLeft() => true | JoinDual() => true | JoinCausing() => true
  | JoinRight() => false | JoinNone() => false | JoinTransparent() => false
fun backward(k: ArabicJoining): bool = case+ k of
  | JoinRight() => true | JoinDual() => true | JoinCausing() => true
  | JoinLeft() => false | JoinNone() => false | JoinTransparent() => false
fun connected(current: ArabicJoining,prior: ArabicJoining,next: ArabicJoining): ArabicForm = let
  val incoming=backward(current) andalso forward(prior)
  val outgoing=forward(current) andalso backward(next)
in if incoming andalso outgoing then FormMedial() else if incoming then FormFinal()
  else if outgoing then FormInitial() else FormIsolated() end
implement arabic_test_model(current,prior,next) = case+ current of
  | JoinNone() => FormNone() | JoinTransparent() => FormNone()
  | JoinRight() => connected(current,prior,next) | JoinLeft() => connected(current,prior,next)
  | JoinDual() => connected(current,prior,next) | JoinCausing() => connected(current,prior,next)
implement arabic_test_form_code(form) = case+ form of
  | FormNone() => 0 | FormInitial() => 1 | FormMedial() => 2 | FormFinal() => 4 | FormIsolated() => 8
