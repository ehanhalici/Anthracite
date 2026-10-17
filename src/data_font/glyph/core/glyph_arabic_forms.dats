#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_text/arabic/joining/arabic_join.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/glyph/core/glyph_arabic_work.sats"
implement glyph_arabic_form(s,node,form,plan) = let
  val old=glyph_storage_core(s,node)
  val info=arabic_mask_info(plan)
  val mask=(old.mask land (info.all lxor 4294967295u)) lor arabic_form_mask(plan,form)
in glyph_storage_set_core(s,node,glyph_run_new_mask(old,mask)) end
implement glyph_arabic_promote(s,node,form,plan) =
  if ilt(node,0) then () else case+ form of
    | FormNone() => () | FormInitial() => glyph_arabic_form(s,node,form,plan)
    | FormMedial() => glyph_arabic_form(s,node,form,plan)
    | FormFinal() => glyph_arabic_form(s,node,form,plan)
    | FormIsolated() => glyph_arabic_form(s,node,form,plan)
