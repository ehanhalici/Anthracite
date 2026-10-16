#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/source/text_source.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_status.sats"
extern fun fixture_exhausted(): int = "mac#anth_die_int"

fun parse_cps {n:nat} .<n>. (n: int(n), input: !Buf, p: int, en: int, cps: !Buf, count: int): int =
  if ige(p,en) then count else if n = 0 then fixture_exhausted() else let
    var next: int = text_skip_space(input,p,en)
  in if ige(next,en) then count else let
      val cp = text_hex(input,next,en)
      val () = buf_set32(cps,count,cp)
    in parse_cps(n-1,input,text_skip_space(input,next,en),en,cps,iadd(count,1)) end end

fun fixture(value: string): ScalarText = let
  val size = c_strlen(value)
  var input = buf_make(iadd(size,1))
  val () = buf_append(input,c_str_ptr(value),size)
  val cps = buf_make(imul(iadd(size,1),4))
  val starts = buf_make(imul(iadd(size,1),4))
  val ends = buf_make(imul(iadd(size,1),4))
  val count = parse_cps(airlock_nat(iadd(size,1)),input,0,size,cps,0)
  val () = buf_free(input)
in ScalarText(cps,starts,ends,count,0) end

fun check_pair(map: !PropertyMap(2)): int = let
  val text = fixture("0061 2067 05D0 2066 0062 2069 2069 05D1")
  val work = bidi_make(map,text)
  val () = bidi_match_isolates(work)
  val pairs = ieq(bidi_match(work,1),6) andalso ieq(bidi_match(work,3),5)
    andalso ieq(bidi_match(work,6),1) andalso ieq(bidi_match(work,0),~1)
  val base = bidi_paragraph_level(work,AutoLtr())
  val () = bidi_explicit_levels(work,base)
  val levels = ieq(bidi_level(work,1),0) andalso ieq(bidi_level(work,2),1)
    andalso ieq(bidi_level(work,3),1) andalso ieq(bidi_level(work,4),2)
    andalso ieq(bidi_level(work,5),1) andalso ieq(bidi_level(work,6),0)
  val () = bidi_dispose(work)
  val () = scalar_dispose(text)
in if pairs andalso levels andalso ieq(base,0) then 0 else 1 end

fun check_direction(map: !PropertyMap(2), value: string, expected: int): int = let
  val text = fixture(value)
  val work = bidi_make(map,text)
  val () = bidi_match_isolates(work)
  val level = bidi_paragraph_level(work,AutoLtr())
  val () = bidi_dispose(work)
  val () = scalar_dispose(text)
in if ieq(level,expected) then 0 else 1 end

fun check_override(map: !PropertyMap(2)): int = let
  val text = fixture("202E 0061 2066 0062 2069 0063 202C 0064")
  val work = bidi_make(map,text)
  val () = bidi_match_isolates(work)
  val () = bidi_explicit_levels(work,0)
  val classes = not(bidi_class_is_ltr(bidi_current(work,1)))
    andalso not(bidi_class_is_ltr(bidi_current(work,2))) andalso bidi_class_is_ltr(bidi_current(work,3))
    andalso not(bidi_class_is_ltr(bidi_current(work,4))) andalso bidi_class_is_ltr(bidi_current(work,7))
  val levels = ieq(bidi_level(work,1),1) andalso ieq(bidi_level(work,3),2) andalso ieq(bidi_level(work,4),1)
  val () = bidi_dispose(work)
  val () = scalar_dispose(text)
in if classes andalso levels then 0 else 1 end

fun check_properties(map: !PropertyMap(2)): int =
  if ieq(property_value(map,1424),1) andalso ieq(property_value(map,1564),2)
    andalso ieq(property_value(map,65),0) andalso ieq(property_value(map,8204),18) then 0 else 1

fun check_all(map: !PropertyMap(2)): int =
  check_pair(map) + check_override(map) + check_properties(map)
  + check_direction(map,"2067 05D0 2069 0061",0)
  + check_direction(map,"2067 05D0 0061",0)
  + check_direction(map,"2066 0061 2069 05D0",1)

fun run(): int = case+ property_load(c_argv(1),BidiProperty()) of
  | ~PropertyRejected(error) => 1
  | ~PropertyLoaded(map) => let
      val before = mem_live()
      val errors = check_all(map)
      val balanced = if ieq(before,mem_live()) then 0 else 1
      val () = property_dispose(map)
      val () = println!("event=bidi_core_conformance errors=",errors)
    in iadd(errors,balanced) end

implement main0() = if ine(c_argc(),2) then exit(2) else if igt(run(),0) then exit(1) else ()
