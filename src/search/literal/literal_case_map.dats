#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "search/literal/literal_search.sats"
staload "search/literal/literal_work.sats"
fun scalar_valid(cp: int): bool = ige(cp,0) andalso ile(cp,UNICODE_MAX_SCALAR)
  andalso not(ige(cp,UNICODE_SURROGATE_START) andalso ilt(cp,UNICODE_SURROGATE_LIMIT))
fun entry_word(i: int): int = iadd(SEARCH_CASE_HEADER_WORDS,imul(i,SEARCH_CASE_ENTRY_WORDS))
fun search{n:nat} .<n>. (fuel: int(n),table: !Buf,cp: int,low: int,high: int): int =
  if ige(low,high) then cp else if not(recursion_fuel_available(fuel)) then cp else let
    val middle=iadd(low,idiv(isub(high,low),2)) val at=entry_word(middle)
    val value=buf_get32(table,iadd(at,SEARCH_CASE_FIELD_SCALAR))
  in if ieq(value,cp) then buf_get32(table,iadd(at,SEARCH_CASE_FIELD_REPRESENTATIVE))
    else if ilt(cp,value) then search(fuel-1,table,cp,low,middle)
    else search(fuel-1,table,cp,iadd(middle,1),high) end
implement literal_case_lookup(table,cp) = search(SEARCH_CASE_LOOKUP_BITS,table,cp,0,buf_get32(table,SEARCH_CASE_HEADER_COUNT))
fun entries{n:nat} .<n>. (left: int(n),table: !Buf,i: int,previous: int): bool =
  if left = 0 then true else let val at=entry_word(i)
    val cp=buf_get32(table,iadd(at,SEARCH_CASE_FIELD_SCALAR))
    val folded=buf_get32(table,iadd(at,SEARCH_CASE_FIELD_REPRESENTATIVE))
  in igt(cp,previous) andalso scalar_valid(cp) andalso scalar_valid(folded)
    andalso ieq(literal_case_lookup(table,folded),folded) andalso entries(left-1,table,iadd(i,1),cp) end
implement literal_case_valid(table) = let
  val bytes=buf_len(table) val header=imul(SEARCH_CASE_HEADER_WORDS,WORD32_BYTES)
  val record=imul(SEARCH_CASE_ENTRY_WORDS,WORD32_BYTES)
in if ilt(bytes,header) then false else let val count=buf_get32(table,SEARCH_CASE_HEADER_COUNT)
  in ieq(buf_get32(table,SEARCH_CASE_HEADER_MAGIC),SEARCH_CASE_MAGIC) andalso ieq(buf_get32(table,SEARCH_CASE_HEADER_VERSION),SEARCH_CASE_VERSION)
    andalso ige(count,0) andalso ieq(imod(isub(bytes,header),record),0)
    andalso ieq(count,idiv(isub(bytes,header),record)) andalso entries(airlock_nat(count),table,0,~1) end end
