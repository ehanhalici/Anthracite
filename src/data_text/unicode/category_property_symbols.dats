#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/source/text_source.sats"
staload "data_text/line_break/line_property_symbols.sats"

fun categories_20(b: !Buf,p: int,en: int): int =
  if text_token_is(b,p,en,"Sc") then 20
  else if text_token_is(b,p,en,"Sk") then 21
  else if text_token_is(b,p,en,"So") then 22
  else if text_token_is(b,p,en,"Zs") then 23
  else if text_token_is(b,p,en,"Zl") then 24
  else if text_token_is(b,p,en,"Zp") then 25
  else if text_token_is(b,p,en,"Cc") then 26
  else if text_token_is(b,p,en,"Cf") then 27
  else if text_token_is(b,p,en,"Cs") then 28
  else if text_token_is(b,p,en,"Co") then 29
  else ~1

fun categories_10(b: !Buf,p: int,en: int): int =
  if text_token_is(b,p,en,"Nl") then 10
  else if text_token_is(b,p,en,"No") then 11
  else if text_token_is(b,p,en,"Pc") then 12
  else if text_token_is(b,p,en,"Pd") then 13
  else if text_token_is(b,p,en,"Ps") then 14
  else if text_token_is(b,p,en,"Pe") then 15
  else if text_token_is(b,p,en,"Pi") then 16
  else if text_token_is(b,p,en,"Pf") then 17
  else if text_token_is(b,p,en,"Po") then 18
  else if text_token_is(b,p,en,"Sm") then 19
  else categories_20(b,p,en)

fun categories_0(b: !Buf,p: int,en: int): int =
  if text_token_is(b,p,en,"Cn") then 0
  else if text_token_is(b,p,en,"Lu") then 1
  else if text_token_is(b,p,en,"Ll") then 2
  else if text_token_is(b,p,en,"Lt") then 3
  else if text_token_is(b,p,en,"Lm") then 4
  else if text_token_is(b,p,en,"Lo") then 5
  else if text_token_is(b,p,en,"Mn") then 6
  else if text_token_is(b,p,en,"Mc") then 7
  else if text_token_is(b,p,en,"Me") then 8
  else if text_token_is(b,p,en,"Nd") then 9
  else categories_10(b,p,en)

implement category_symbol_of(b,p,en) = categories_0(b,p,en)
