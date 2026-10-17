#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/source/text_source.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/line_break/line_engine.sats"
staload "data_text/line_break/line_break_map.sats"
staload "text/line_break/line_fixture.sats"
staload "text/line_break/line_conformance.sats"

extern fun cases_exhausted(): int = "mac#anth_die_int"

fun allowed(d: LineBreak): int = case+ d of
  | BreakForbidden() => 0 | BreakOptional() => 1 | BreakMandatory() => 1

fun compare {fuel:nat} .<fuel>. (fuel: int(fuel),actual: !LineBreakMap,expected: !Buf,
  i: int,n: int,errors: int,line: int): int =
  if igt(i,n) then errors else if fuel = 0 then cases_exhausted() else let
    val want=buf_get(expected,i)
    val got=allowed(line_break_at(actual,i))
    val error=if ieq(want,got) then 0 else 1
    val ()=if igt(error,0) then println!("event=line_mismatch line=",line,
      " scalar=",i," expected=",want," actual=",got) else ()
  in compare(fuel-1,actual,expected,iadd(i,1),n,iadd(errors,error),line) end

fun check(map: !PropertyMap(4),width: !PropertyMap(5),category: !PropertyMap(6),
  emoji: !UnicodeDb,source: !Buf,start: int,en: int,line: int): int = let
  val baseline=mem_live()
  val+ ~LineFixture(text,expected)=line_fixture_parse(source,start,en)
  val n=scalar_count(text)
  val actual=line_boundaries(map,width,category,emoji,text)
  val errors=compare(airlock_nat(iadd(n,2)),actual,expected,0,n,0,line)
  val ()=line_breaks_dispose(actual)
  val ()=scalar_dispose(text)
  val ()=buf_free(expected)
in iadd(errors,if ieq(mem_live(),baseline) then 0 else 1) end

fun lines {fuel:nat} .<fuel>. (fuel: int(fuel),map: !PropertyMap(4),width: !PropertyMap(5),
  category: !PropertyMap(6),emoji: !UnicodeDb,source: !Buf,pos: int,en: int,
  line: int,summary: LineSummary): LineSummary =
  if ige(pos,en) then summary else if fuel = 0 then @{cases=0,errors=cases_exhausted()} else let
    val finish=text_line_end(source,pos,en)
    val p=text_skip_space(source,pos,finish)
    val valid=ilt(p,finish) andalso ine(buf_get(source,p),35)
    val errors: int=if valid then check(map,width,category,emoji,source,p,finish,line) else 0
    val next= @{cases=iadd(summary.cases,if valid then 1 else 0),errors=iadd(summary.errors,errors)}
  in lines(fuel-1,map,width,category,emoji,source,iadd(finish,1),en,iadd(line,1),next) end

implement line_check_file(map,width,category,emoji,path) = case+ text_file_read(path) of
  | ~TextFileError(code) => @{cases=0,errors=1}
  | ~TextFile(source) => let
    val n=buf_len(source)
    val summary=lines(airlock_nat(iadd(n,1)),map,width,category,emoji,source,0,n,1,@{cases=0,errors=0})
    val ()=buf_free(source)
  in summary end
