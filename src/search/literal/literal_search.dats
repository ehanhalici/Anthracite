#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/source/text_source.sats"
staload "search/literal/literal_search.sats"
staload "search/literal/literal_work.sats"
fun next_state{n:nat} .<n>. (fuel: int(n),query: !Buf,failure: !Buf,state: int,byte: int): int =
  if ieq(buf_get(query,state),byte) then iadd(state,1) else if ile(state,0) then 0
  else if not(recursion_fuel_available(fuel)) then 0
  else next_state(fuel-1,query,failure,buf_get32(failure,isub(state,1)),byte)
fun build_failure{n:nat} .<n>. (left: int(n),query: !Buf,failure: !Buf,i: int,state: int): void =
  if left = 0 then () else let
    val next=next_state(airlock_nat(iadd(state,1)),query,failure,state,buf_get(query,i))
    val ()=buf_set32(failure,i,next)
  in build_failure(left-1,query,failure,iadd(i,1),next) end
fun pattern(table: Buf,source: !Buf): LiteralPattern = let
  var query=buf_make(0) var starts=buf_make(0) var ends=buf_make(0)
  val ()=literal_fold(table,source,query,starts,ends) val length=buf_len(query)
  val failure=buf_make(imul(length,WORD32_BYTES)) val ()=buf_zero(failure)
  val ()=build_failure(airlock_nat(imax(0,isub(length,1))),query,failure,1,0)
  val ()=buf_free(starts) val ()=buf_free(ends)
in LiteralPattern(table,query,failure) end
implement literal_pattern_open(query,path) =
  if igt(buf_len(query),LITERAL_QUERY_LIMIT_BYTES) orelse igt(fs_size(path),SEARCH_CASE_LIMIT_BYTES) then None_vt() else case+ text_file_read(path) of
  | ~TextFileError(code) => None_vt() | ~TextFile(table) =>
    if literal_case_valid(table) then Some_vt(pattern(table,query)) else let val ()=buf_free(table) in None_vt() end
implement literal_pattern_free(p) = let val+ ~LiteralPattern(table,query,failure)=p
  val ()=buf_free(table) val ()=buf_free(query) in buf_free(failure) end
implement literal_pattern_release(p) = case+ p of | ~None_vt() => () | ~Some_vt(pattern) => literal_pattern_free(pattern)
fun emit(ranges: !Buf,index: int,start: int,finish: int): void = let val at=imul(index,LITERAL_RANGE_WORDS)
  val ()=buf_set32(ranges,iadd(at,LITERAL_RANGE_START),start)
in buf_set32(ranges,iadd(at,LITERAL_RANGE_FINISH),finish) end
fun scan{n:nat} .<n>. (left: int(n),query: !Buf,failure: !Buf,text: !Buf,starts: !Buf,ends: !Buf,
  ranges: !Buf,limit: int,i: int,state: int,count: int): int =
  if left = 0 then count else if ige(count,limit) then count else let
    val next=next_state(airlock_nat(iadd(state,1)),query,failure,state,buf_get(text,i)) val size=buf_len(query)
    val matched=ieq(next,size)
    val ()=if matched then emit(ranges,count,buf_get32(starts,isub(iadd(i,1),size)),buf_get32(ends,i)) else ()
    val state=if matched then buf_get32(failure,isub(size,1)) else next
  in scan(left-1,query,failure,text,starts,ends,ranges,limit,iadd(i,1),state,iadd(count,if matched then 1 else 0)) end
fun collected(query: !Buf,failure: !Buf,text: !Buf,starts: !Buf,ends: !Buf,ranges: !Buf,limit: int): int =
  if ieq(buf_len(query),0) then 0 else scan(airlock_nat(buf_len(text)),query,failure,text,starts,ends,ranges,limit,0,0,0)
implement literal_collect(p,source,ranges,limit) = let val ()=buf_set_len(ranges,0)
in if igt(buf_len(source),LITERAL_SOURCE_LIMIT_BYTES) orelse ilt(limit,0) orelse igt(limit,LITERAL_MATCH_LIMIT) then ~1 else let
  val+ LiteralPattern(table,query,failure)=p var text=buf_make(0) var starts=buf_make(0) var ends=buf_make(0)
  val ()=literal_fold(table,source,text,starts,ends)
  val ()=buf_ensure(ranges,imul(imul(limit,LITERAL_RANGE_WORDS),WORD32_BYTES))
  val count=collected(query,failure,text,starts,ends,ranges,limit)
  val ()=buf_set_len(ranges,imul(imul(count,LITERAL_RANGE_WORDS),WORD32_BYTES))
  val ()=buf_free(text) val ()=buf_free(starts) val ()=buf_free(ends)
in count end end
