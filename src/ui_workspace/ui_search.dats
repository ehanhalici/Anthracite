#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_search.sats"
staload "airlock.sats"
staload "os/diag.sats"
staload "data_ast/doc.sats"
staload "ui_workspace/ui_tab.sats"
staload "search/ix_store.sats"
staload "search/ix_fold.sats"
staload "search/ix_query.sats"
staload "search/ix_build.sats"
staload "search/ix_match.sats"



fun init_and_step_index(vault: !Buf, ixf: &Buf >> _, ixp: &Buf >> _, ixs: &Buf >> _, ixb: &Buf >> _): void = let
  var trunc: int = 0
  val () = ix_walk_vault(vault, ixf, ixp, trunc)
  val () = seen_int(ix_step_all(vault, ixf, ixs, ixp, ixb, 5000000000L))
in
end

implement refresh_search(vault, q, hits, hmeta, hn) = let
  val () = bclear(hits); val () = bclear(hmeta); val () = hn := 0
  var ixf = buf_make(64); var ixs = buf_make(64); var ixp = buf_make(64)
  var ixb = buf_make(64); var hjump = buf_make(64)
  val () = init_and_step_index(vault, ixf, ixp, ixs, ixb)
  var nfiles_hit: int = 0; var is_partial: int = 0
  val dummy_tabs = TNil()
  val () = ix_match_search(q, vault, dummy_tabs, ixf, ixs, ixp, ixb, hits, hmeta, hjump, hn, nfiles_hit, is_partial)
  val () = tabs_free(dummy_tabs)
  val () = buf_free(ixf); val () = buf_free(ixs); val () = buf_free(ixp)
  val () = buf_free(ixb); val () = buf_free(hjump)
in
end

implement search_dir(path, q, hits, hmeta, hn, depth) =
  refresh_search(path, q, hits, hmeta, hn)

extern fun hit_head_exh(hmeta: !Buf, r: int): int = "mac#anth_die_int"

fun hit_head_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), hmeta: !Buf, r: int): int =
  if recfuel > 0 then (
    if ilt(r, 0) then ~1
    else if ilt(buf_get32(hmeta, imul(r, 4)), 0) then r
    else hit_head_m(recfuel - 1, hmeta, isub(r, 1))
  ) else hit_head_exh(hmeta, r)

implement find_hit_file(hmeta, hits, row, dst) = let
  val () = bclear(dst)
  val head_row = hit_head_m(airlock_nat(MAX_REC_FUEL), hmeta, row)
in
  if ige(head_row, 0) then let
    val off = buf_get32(hmeta, iadd(imul(head_row, 4), 1))
    val n = buf_get32(hmeta, iadd(imul(head_row, 4), 2))
  in
    bcat(dst, hits, off, iadd(off, n))
  end else ()
end

implement hit_text(hits, off, n, f, r, x, y, c) =
  if ile(n, 0) then 0
  else let
    val cap = buf_cap(hits)
  in
    font_draw_at(f, r, x, y, hits, off, n, c)
  end
