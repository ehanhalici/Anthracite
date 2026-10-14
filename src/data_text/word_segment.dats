#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_db.sats"
staload "data_text/unicode_property.sats"
staload "data_text/word_types.sats"
staload "data_text/word_predicates.sats"

extern fun word_exhausted(): int = "mac#anth_die_int"

fun next_index {fuel:nat} .<fuel>. (
  fuel: int(fuel), map: !PropertyMap(1), text: !ScalarText, i: int, n: int
): int =
  if ige(i,n) then n else if fuel = 0 then word_exhausted() else let
    val k = word_kind_of(property_value(map,scalar_value(text,i)))
  in if word_is_ignored(k) then next_index(fuel-1,map,text,iadd(i,1),n) else i end

fun future(map: !PropertyMap(1), text: !ScalarText, i: int, n: int): WordKind = let
  val index = next_index(airlock_nat(isub(n,i)),map,text,i,n)
in if ige(index,n) then WMissing() else word_kind_of(property_value(map,scalar_value(text,index))) end

fun segment {fuel:nat} .<fuel>. (
  fuel: int(fuel), map: !PropertyMap(1), db: !UnicodeDb, text: !ScalarText,
  i: int, n: int, state: WordState, output: !Buf
): void =
  if ige(i,n) then buf_set(output,n,1) else if fuel = 0 then let val stop = word_exhausted() in () end
  else let
    val cp = scalar_value(text,i)
    val k = word_kind_of(property_value(map,cp))
    val next = if word_needs_future(k) then future(map,text,iadd(i,1),n) else WMissing()
    val step = word_step(map,db,state,cp,next)
    val () = buf_set(output,i,if step.boundary then 1 else 0)
  in segment(fuel-1,map,db,text,iadd(i,1),n,step.state,output) end

implement word_boundaries(map,db,text) = let
  val n = scalar_count(text)
  val output = buf_make(iadd(n,1))
  val () = segment(airlock_nat(n),map,db,text,0,n,word_initial(),output)
in output end
