#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "search/literal/literal_search.sats"
staload "ui_workspace/common/ui_common.sats"
staload "core_runtime/performance.sats"
fun bytes(text: string): Buf = let var result=buf_make(0)
  val ()=buffer_append_string(result,text) in result end
fun checked(pattern: LiteralPattern,text: !Buf,count: int,first: int,finish: int): int = let
    var ranges=buf_make(0)
    val found=literal_collect(pattern,text,ranges,32)
    val start=buf_get32(ranges,LITERAL_RANGE_START)
    val stop=buf_get32(ranges,iadd(imul(imax(0,isub(found,1)),LITERAL_RANGE_WORDS),LITERAL_RANGE_FINISH))
    val ()=literal_pattern_free(pattern)
    val ()=buf_free(ranges)
in if ieq(found,count) andalso (ieq(count,0) orelse (ieq(start,first) andalso ieq(stop,finish))) then 0 else 1 end
fun check(query: string,source: string,count: int,first: int,finish: int): int = let
  val q=bytes(query) val text=bytes(source)
  val errors=case+ literal_pattern_open(q,c_argv(1)) of
    | ~None_vt() => 1 | ~Some_vt(pattern) => checked(pattern,text,count,first,finish)
  val ()=buf_free(q) val ()=buf_free(text)
in errors end
fun cases(): int =
  check("i","İIıi",4,0,6)+check("ABA","xababaY",2,1,6)
  +check("ά","ΆΛΦΑ άλφα",2,0,11)+check("աբ","ԱԲԳաբգ",2,0,10)
  +check("ა","Აა",2,0,6)+check("𐐨","𐐀𐐨",2,0,8)
  +check("file:abc [[.*]]","x file:abc [[.*]] y",1,2,17)
  +check("A B","A xx B\nA B",1,7,10)+check("","abc",0,0,0)
  +check("ss","ßẞ",0,0,0)+check("ß","ßẞ",2,0,5)
implement main0() = let
  val before=mem_live() val ()=performance_enable(1) val ()=performance_reset()
  val errors=cases() val balanced=ieq(before,mem_live())
  val raw=performance_value(PERF_DOCUMENT_LOADS)=0ULL andalso performance_value(PERF_AST_PARSES)=0ULL
  val ()=performance_enable(0)
  val ()=println!("event=literal_search errors=",errors," balanced=",balanced," raw=",raw)
in if igt(errors,0) orelse not(balanced) orelse not(raw) then exit(1) else () end
