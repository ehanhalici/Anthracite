#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/resources/font.sats"
staload "data_font/resources/private/font_storage.sats"
staload "data_font/resources/font_registry.sats"

extern fun exhausted(): int = "mac#anth_die_int"
fun bounded(value: int): int = if ige(value,SIGNED_INT_MAX_VALUE) then exhausted() else value

implement font_registry_next() = let
  val value=bounded(iadd(font_registry_load(),1))
  val ()=font_registry_store(value)
in value end

implement font_registry_id(f) = f_registry(f)
