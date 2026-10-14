#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/text_source.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/opentype_classdef.sats"
staload "data_font/opentype_device.sats"
staload "font_fixture.sats"
staload "opentype_fixture.sats"
extern fun fixture_exhausted(): int = "mac#anth_die_int"

fun copy {n:nat} .<n>. (n: int(n),s: string,b: !Buf,i: int): void =
  if n = 0 then () else let val ()=buf_set(b,i,c_str_byte(s,i)) in copy(n-1,s,b,iadd(i,1)) end

fun words {fuel:nat} .<fuel>. (fuel: int(fuel),source: !Buf,p: int,en: int,b: !Buf,count: int): int =
  if ige(text_skip_space(source,p,en),en) then count else if fuel = 0 then fixture_exhausted() else let
    var next: int=text_skip_space(source,p,en)
    val start=next
    val value=text_hex(source,next,en)
    val ()=if ile(next,start) orelse ilt(value,0) orelse igt(value,65535)
      then let val failed=fixture_exhausted() in seen_int(failed) end else ()
    val ()=fixture_put16(b,iadd(8,imul(count,2)),value)
  in words(fuel-1,source,next,en,b,iadd(count,1)) end

implement ot_fixture_words(s) = let
  val n=c_strlen(s)
  val source=buf_make(n)
  val b=buf_make(iadd(n,8))
  val ()=copy(airlock_nat(n),s,source,0)
  val count=words(airlock_nat(iadd(n,1)),source,0,n,b,0)
  val ()=buf_free(source)
  val ()=buf_set_len(b,iadd(8,imul(count,2)))
in b end

implement ot_fixture_span(b) = @{offset=8,length=isub(buf_len(b),8)}
implement ot_fixture_put16(b,p,v) = fixture_put16(b,iadd(8,p),v)
implement ot_fixture_read16(b,p) = ot_u16(b,ot_fixture_span(b),p)
implement ot_fixture_reject_coverage(b,s,glyphs) = case+ ot_coverage_parse(b,s,glyphs) of
  | ~CoverageRejected(e) => 0 | ~CoverageAccepted(c) => 1
implement ot_fixture_reject_class(b,s,glyphs) = case+ ot_classdef_parse(b,s,glyphs) of
  | ~ClassRejected(e) => 0 | ~ClassAccepted(c) => 1
implement ot_fixture_reject_device(b,s) = case+ ot_device_parse(b,s) of
  | ~DeviceRejected(e) => 0 | ~DeviceAccepted(d) => 1 | ~DeviceVariation(a,b) => 1
