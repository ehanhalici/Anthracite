#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/unicode/unicode_db.sats"
staload "text/line_break/line_conformance.sats"

fun with_emoji(map: !PropertyMap(4),width: !PropertyMap(5),category: !PropertyMap(6)): int =
  case+ unicode_load(c_argv(4)) of
  | ~UnicodeDataError() => 1
  | ~UnicodeLoaded(db) => let
    val summary=line_check_file(map,width,category,db,c_argv(5))
    val ()=unicode_dispose(db)
    val ()=println!("event=line_conformance cases=",summary.cases," errors=",summary.errors)
  in iadd(summary.errors,if ieq(summary.cases,19346) then 0 else 1) end

fun with_category(map: !PropertyMap(4),width: !PropertyMap(5)): int =
  case+ property_load(c_argv(3),CategoryProperty()) of
  | ~PropertyRejected(error) => 1
  | ~PropertyLoaded(category) => let
    val errors=with_emoji(map,width,category)
    val ()=property_dispose(category)
  in errors end

fun with_width(map: !PropertyMap(4)): int = case+ property_load(c_argv(2),EastAsianProperty()) of
  | ~PropertyRejected(error) => 1
  | ~PropertyLoaded(width) => let val errors=with_category(map,width) val ()=property_dispose(width) in errors end

fun run(): int = case+ property_load(c_argv(1),LineProperty()) of
  | ~PropertyRejected(error) => 1
  | ~PropertyLoaded(map) => let val errors=with_width(map) val ()=property_dispose(map) in errors end

implement main0() = if ine(c_argc(),6) then exit(2) else let
  val baseline=mem_live()
  val errors=run()
  val balanced=ieq(mem_live(),baseline)
  val ()=println!("event=line_ownership balanced=",balanced)
in if igt(errors,0) orelse not(balanced) then exit(1) else () end
