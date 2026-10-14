#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/font.sats"
staload "data_font/font_registry.sats"
staload "font_native_contracts.sats"

fun unique(first: int,second: int,third: int): bool =
  igt(first,0) andalso igt(second,first) andalso igt(third,second)

implement native_font_registry_cases() = let
  val first=font_registry_next() val second=font_registry_next() val third=font_registry_next()
  val f=font_open() val g=font_open()
  val allocated=font_registry_id(f) and other=font_registry_id(g)
  val ()=font_free(f) val ()=font_free(g)
  val fourth=font_registry_next()
  val ok=unique(first,second,third) andalso igt(allocated,0) andalso igt(other,allocated)
    andalso igt(fourth,third)
  val ()=println!("event=native_font_registry unique=",ok," allocated=",iadd(allocated,0))
in if ok then 0 else 1 end
