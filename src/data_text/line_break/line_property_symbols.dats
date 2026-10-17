#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/source/text_source.sats"
staload "data_text/line_break/line_property_symbols.sats"

fun symbols_36(b: !Buf,p: int,en: int): int =
  if text_token_is(b,p,en,"PR") then 36
  else if text_token_is(b,p,en,"QU") then 37
  else if text_token_is(b,p,en,"RI") then 38
  else if text_token_is(b,p,en,"SA") then 39
  else if text_token_is(b,p,en,"SG") then 40
  else if text_token_is(b,p,en,"SP") then 41
  else if text_token_is(b,p,en,"SY") then 42
  else if text_token_is(b,p,en,"VF") then 43
  else if text_token_is(b,p,en,"VI") then 44
  else if text_token_is(b,p,en,"WJ") then 45
  else if text_token_is(b,p,en,"ZW") then 46
  else if text_token_is(b,p,en,"ZWJ") then 47
  else if text_token_is(b,p,en,"GL") then 48 else ~1

fun symbols_24(b: !Buf,p: int,en: int): int =
  if text_token_is(b,p,en,"ID") then 24
  else if text_token_is(b,p,en,"IN") then 25
  else if text_token_is(b,p,en,"IS") then 26
  else if text_token_is(b,p,en,"JL") then 27
  else if text_token_is(b,p,en,"JT") then 28
  else if text_token_is(b,p,en,"JV") then 29
  else if text_token_is(b,p,en,"LF") then 30
  else if text_token_is(b,p,en,"NL") then 31
  else if text_token_is(b,p,en,"NS") then 32
  else if text_token_is(b,p,en,"NU") then 33
  else if text_token_is(b,p,en,"OP") then 34
  else if text_token_is(b,p,en,"PO") then 35
  else symbols_36(b,p,en)

fun symbols_12(b: !Buf,p: int,en: int): int =
  if text_token_is(b,p,en,"CL") then 12
  else if text_token_is(b,p,en,"CM") then 13
  else if text_token_is(b,p,en,"CP") then 14
  else if text_token_is(b,p,en,"CR") then 15
  else if text_token_is(b,p,en,"EB") then 16
  else if text_token_is(b,p,en,"EM") then 17
  else if text_token_is(b,p,en,"EX") then 18
  else if text_token_is(b,p,en,"H2") then 19
  else if text_token_is(b,p,en,"H3") then 20
  else if text_token_is(b,p,en,"HH") then 21
  else if text_token_is(b,p,en,"HL") then 22
  else if text_token_is(b,p,en,"HY") then 23
  else symbols_24(b,p,en)

fun symbols_0(b: !Buf,p: int,en: int): int =
  if text_token_is(b,p,en,"XX") then 0
  else if text_token_is(b,p,en,"AI") then 1
  else if text_token_is(b,p,en,"AK") then 2
  else if text_token_is(b,p,en,"AL") then 3
  else if text_token_is(b,p,en,"AP") then 4
  else if text_token_is(b,p,en,"AS") then 5
  else if text_token_is(b,p,en,"B2") then 6
  else if text_token_is(b,p,en,"BA") then 7
  else if text_token_is(b,p,en,"BB") then 8
  else if text_token_is(b,p,en,"BK") then 9
  else if text_token_is(b,p,en,"CB") then 10
  else if text_token_is(b,p,en,"CJ") then 11
  else symbols_12(b,p,en)

implement line_symbol_of(b,p,en) = symbols_0(b,p,en)
implement east_asian_symbol_of(b,p,en) =
  if text_token_is(b,p,en,"N") then 0 else if text_token_is(b,p,en,"Na") then 1
  else if text_token_is(b,p,en,"A") then 2 else if text_token_is(b,p,en,"F") then 3
  else if text_token_is(b,p,en,"W") then 4 else if text_token_is(b,p,en,"H") then 5 else ~1
