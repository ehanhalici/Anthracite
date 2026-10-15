#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/doc.sats"
staload "data_ast/ast.sats"
staload "search/ix_store.sats"
staload "search/ix_fold.sats"
staload "search/ix_build.sats"
staload "ui_workspace/ui_common.sats"

fun iand(a: int, n: int): int = anth_iand(a, n)

fun ends_with_md(b: !Buf): bool = let
  val n = buf_len(b)
in
  if ilt(n, 3) then false
  else ieq(buf_get(b, isub(n, 3)), 46) andalso ieq(buf_get(b, isub(n, 2)), 109) andalso ieq(buf_get(b, isub(n, 1)), 100)
end

fun feed_bloom_trigrams_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ixb: !Buf, fid: int, fbuf: !Buf, p: int, limit: int): void =
  if recfuel > 0 then (
    if ile(p, limit) then let
      val b0 = buf_get(fbuf, p)
      val b1 = buf_get(fbuf, iadd(p, 1))
      val b2 = buf_get(fbuf, iadd(p, 2))
      val () = ix_bloom_set_trigram(ixb, fid, b0, b1, b2)
    in
      feed_bloom_trigrams_m(recfuel - 1, ixb, fid, fbuf, iadd(p, 1), limit)
    end else ()
  ) else ()

fun feed_bloom_leaf(d: !Doc, fid: int, ixb: !Buf, cs: int, ce: int, fbuf: &Buf >> _, omap: &Buf >> _): void =
  if ige(isub(ce, cs), 3) then let
    val () = buf_set_len(fbuf, 0)
    val () = buf_set_len(omap, 0)
    val () = fold_range_doc(d, cs, ce, fbuf, omap)
    val flen = buf_len(fbuf)
    val () = feed_bloom_trigrams_m(airlock_nat(MAX_REC_FUEL), ixb, fid, fbuf, 0, isub(flen, 3))
  in
  end else ()

fun extract_heading(d: !Doc, fid: int, i: int, k: NodeKind, ixs: &Buf >> _, ixp: &Buf >> _, omap: &Buf >> _): void = let
  val cs0 = doc_node_cstart(d, i)
  val ce0 = doc_node_cend(d, i)
  val cs = if igt(ce0, cs0) then cs0 else doc_node_start(d, i)
  val ce = if igt(ce0, cs0) then ce0 else doc_node_end(d, i)
  val toff = buf_len(ixp)
  val () = buf_set_len(omap, 0)
  val () = fold_range_doc(d, cs, ce, ixp, omap)
  val tlen = isub(buf_len(ixp), toff)
  val line = doc_line_of(d, cs)
  val aux = doc_node_aux(d, i)
  val _ = ix_sym_add(ixs, fid, kind_code(k), doc_node_start(d, i), doc_node_end(d, i), line, toff, tlen, aux)
in
end

fun extract_child_sym(d: !Doc, fid: int, i: int, k: NodeKind, ck: NodeKind, aux: int, ixs: &Buf >> _, ixp: &Buf >> _, omap: &Buf >> _): void = let
  val c = doc_find_child(d, i, ck)
in
  if ige(c, 0) then let
    val cs = doc_node_start(d, c)
    val ce = doc_node_end(d, c)
    val toff = buf_len(ixp)
    val () = buf_set_len(omap, 0)
    val () = fold_range_doc(d, cs, ce, ixp, omap)
    val tlen = isub(buf_len(ixp), toff)
    val line = doc_line_of(d, cs)
    val _ = ix_sym_add(ixs, fid, kind_code(k), doc_node_start(d, i), doc_node_end(d, i), line, toff, tlen, aux)
  in
  end else ()
end

fun extract_sym_leaf(d: !Doc, fid: int, i: int, k: NodeKind, aux: int, ixs: &Buf >> _, ixp: &Buf >> _, omap: &Buf >> _): void = let
  val cs = doc_node_start(d, i)
  val ce = doc_node_end(d, i)
  val toff = buf_len(ixp)
  val () = buf_set_len(omap, 0)
  val () = fold_range_doc(d, cs, ce, ixp, omap)
  val tlen = isub(buf_len(ixp), toff)
  val line = doc_line_of(d, cs)
  val _ = ix_sym_add(ixs, fid, kind_code(k), cs, ce, line, toff, tlen, aux)
in
end

fun extract_one_sym(d: !Doc, fid: int, i: int, k: NodeKind, ixs: &Buf >> _, ixp: &Buf >> _, omap: &Buf >> _): void =
  if is_heading(k) then extract_heading(d, fid, i, k, ixs, ixp, omap)
  else if is_kind(k, KTag) then extract_sym_leaf(d, fid, i, k, 0, ixs, ixp, omap)
  else if is_kind(k, KWiki) then extract_child_sym(d, fid, i, k, KWikiTarget, 0, ixs, ixp, omap)
  else if is_kind(k, KLink) then extract_child_sym(d, fid, i, k, KLinkDest, 0, ixs, ixp, omap)
  else if is_kind(k, KTask) then extract_sym_leaf(d, fid, i, k, doc_node_aux(d, i), ixs, ixp, omap)
  else if is_kind(k, KCallout) then extract_child_sym(d, fid, i, k, KInfo, doc_node_aux(d, i), ixs, ixp, omap)
  else if is_kind(k, KCode) then extract_child_sym(d, fid, i, k, KInfo, 0, ixs, ixp, omap)
  else ()

fun is_searchable_leaf(k: NodeKind, flags: int): bool =
  if not(kind_is_leaf(k)) then false
  else if is_kind(k, KMark) orelse is_kind(k, KLinkDest) orelse is_kind(k, KLinkTitle) then false
  else if iand(flags, FL_READ_HIDDEN) != 0 then false
  else true

fun extract_node(d: !Doc, fid: int, i: int, ixs: &Buf >> _, ixp: &Buf >> _, ixb: !Buf, fbuf: &Buf >> _, omap: &Buf >> _): void = let
  val k = doc_node_kind(d, i)
  val flags = doc_node_flags(d, i)
  val () = extract_one_sym(d, fid, i, k, ixs, ixp, omap)
  val () = if is_searchable_leaf(k, flags) then
    feed_bloom_leaf(d, fid, ixb, doc_node_start(d, i), doc_node_end(d, i), fbuf, omap)
  else ()
in
end

fun extract_loop_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, fid: int, i: int, n: int,
  ixs: &Buf >> _, ixp: &Buf >> _, ixb: !Buf, fbuf: &Buf >> _, omap: &Buf >> _
): void =
  if recfuel > 0 then (
    if ilt(i, n) then let
      val () = extract_node(d, fid, i, ixs, ixp, ixb, fbuf, omap)
    in
      extract_loop_m(recfuel - 1, d, fid, iadd(i, 1), n, ixs, ixp, ixb, fbuf, omap)
    end else ()
  ) else ()

implement ix_extract_doc(d, fid, ixs, ixp, ixb) = let
  val n = doc_nnodes(d)
  var fbuf = buf_make(256)
  var omap = buf_make(256)
  val () = extract_loop_m(airlock_nat(MAX_REC_FUEL), d, fid, 0, n, ixs, ixp, ixb, fbuf, omap)
  val () = buf_free(omap)
  val () = buf_free(fbuf)
in
end

fun path_match_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ixp: !Buf, poff: int, plen: int, p: !Buf, i: int): bool =
  if recfuel > 0 then (
    if ige(i, plen) then true
    else if ine(buf_get(ixp, iadd(poff, i)), buf_get(p, i)) then false
    else path_match_m(recfuel - 1, ixp, poff, plen, p, iadd(i, 1))
  ) else true

fun find_file_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ixf: !Buf, ixp: !Buf, path: !Buf, fid: int, nfiles: int): int =
  if recfuel > 0 then (
    if ige(fid, nfiles) then ~1
    else let
      val poff = ix_file_get(ixf, fid, IX_F_PATHOFF)
      val plen = ix_file_get(ixf, fid, IX_F_PATHLEN)
    in
      if ieq(plen, buf_len(path)) andalso path_match_m(airlock_nat(MAX_REC_FUEL), ixp, poff, plen, path, 0) then fid
      else find_file_m(recfuel - 1, ixf, ixp, path, iadd(fid, 1), nfiles)
    end
  ) else ~1

fun register_file(ixf: &Buf >> _, ixp: &Buf >> _, path: !Buf, sz: int, mt: int): int = let
  val nfiles = ix_file_count(ixf)
  val existing = find_file_m(airlock_nat(MAX_REC_FUEL), ixf, ixp, path, 0, nfiles)
in
  if ige(existing, 0) then let
    val prev_sz = ix_file_get(ixf, existing, IX_F_SIZE)
    val prev_mt = ix_file_get(ixf, existing, IX_F_MTIME)
    val changed = ine(prev_sz, sz) orelse ine(prev_mt, mt)
    val () = if changed then ix_file_set(ixf, existing, IX_F_STATE, 1) else ()
    val () = ix_file_set(ixf, existing, IX_F_SIZE, sz)
    val () = ix_file_set(ixf, existing, IX_F_MTIME, mt)
  in
    existing
  end else let
    val poff = buf_len(ixp)
    val plen = buf_len(path)
    val () = bcat(ixp, path, 0, plen)
    val fid = ix_file_add(ixf, poff, plen, sz, mt, 1, 0, 0, 0)
  in
    fid
  end
end

fun walk_file_entry(ixf: &Buf >> _, ixp: &Buf >> _, path: !Buf): void =
  if ends_with_md(path) then let
    val ps = cstr(path)
    val sz = fs_size(ps)
    val mt = fs_mtime(ps)
    val _ = register_file(ixf, ixp, path, sz, mt)
  in
  end else ()

extern fun walk_dir_exh(dp: ptr, parent: !Buf, ixf: &Buf >> _, ixp: &Buf >> _, d: int, trunc: &int >> _): void = "mac#anth_die_void"

fun is_dot_or_empty(name: !Buf): bool = let
  val n = buf_len(name)
in
  if ieq(n, 0) then true
  else ieq(buf_get(name, 0), 46)
end

fun handle_dir_child {recfuel:nat} .<recfuel, 0>. (recfuel: int(recfuel), child: !Buf, is_d: int, d: int, trunc: &int >> _, ixf: &Buf >> _, ixp: &Buf >> _): void =
  if recfuel > 0 then (
    if is_d != 0 then (
      if ilt(d, MAX_INDEX_DEPTH) then let
        val ps = cstr(child)
        val sub_dp = dir_open(ps)
      in
        if sub_dp != 0 then (
          walk_dir_m(recfuel - 1, sub_dp, child, ixf, ixp, iadd(d, 1), trunc);
          dir_close(sub_dp)
        ) else ()
      end else trunc := 1
    ) else walk_file_entry(ixf, ixp, child)
  ) else ()

and walk_dir_m {recfuel:nat} .<recfuel, 1>. (recfuel: int(recfuel), dp: ptr, parent: !Buf, ixf: &Buf >> _, ixp: &Buf >> _, d: int, trunc: &int >> _): void =
  if recfuel > 0 then let
    var name = buf_make(256)
    var isdir: int = 0
    val ok = dir_next_buf(dp, name, 255, isdir)
    val ns = buf_cstr(name)
    val () = buf_set_len(name, c_strlen(ns))
  in
    if ok = 0 then buf_free(name)
    else if is_dot_or_empty(name) then (
      buf_free(name); walk_dir_m(recfuel - 1, dp, parent, ixf, ixp, d, trunc)
    ) else let
      val child = join2(parent, name)
      val () = buf_free(name)
      val () = handle_dir_child(recfuel - 1, child, fs_isdir(cstr(child)), d, trunc, ixf, ixp)
      val () = buf_free(child)
    in
      walk_dir_m(recfuel - 1, dp, parent, ixf, ixp, d, trunc)
    end
  end else walk_dir_exh(dp, parent, ixf, ixp, d, trunc)

implement ix_walk_vault(vault, ixf, ixp, trunc) = let
  val ps = cstr(vault)
  val dp = dir_open(ps)
in
  if dp != 0 then let
    val () = walk_dir_m(airlock_nat(MAX_REC_FUEL), dp, vault, ixf, ixp, 0, trunc)
    val () = dir_close(dp)
  in
  end else ()
end

implement ix_index_file(path, fid, ixs, ixp, ixb) = let
  val doc = doc_open()
  val ok = doc_load(doc, path)
in
  if ok then let
    val sfirst = ix_sym_count(ixs)
    val () = ix_extract_doc(doc, fid, ixs, ixp, ixb)
    val scnt = isub(ix_sym_count(ixs), sfirst)
    val () = doc_free(doc)
  in
  end else doc_free(doc)
end

fun step_one_file(fid: int, ixf: &Buf >> _, ixs: &Buf >> _, ixp: &Buf >> _, ixb: !Buf): void = let
  val poff = ix_file_get(ixf, fid, IX_F_PATHOFF)
  val plen = ix_file_get(ixf, fid, IX_F_PATHLEN)
  var path = buf_make(iadd(plen, 1))
  val () = bcat(path, ixp, poff, iadd(poff, plen))
  val ps = cstr(path)
  val () = ix_index_file(ps, fid, ixs, ixp, ixb)
  val () = buf_free(path)
  val () = ix_file_set(ixf, fid, IX_F_STATE, 0)
in
end

fun step_loop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), fid: int, nfiles: int, ixf: &Buf >> _, ixs: &Buf >> _, ixp: &Buf >> _, ixb: !Buf, start_ns: lint, budget_ns: lint): int =
  if recfuel > 0 then (
    if ige(fid, nfiles) then 0
    else let
      val elapsed = mono_ns() - start_ns
    in
      if elapsed > budget_ns then 1
      else let
        val st = ix_file_get(ixf, fid, IX_F_STATE)
        val () = if ieq(st, 1) then step_one_file(fid, ixf, ixs, ixp, ixb) else ()
      in
        step_loop_m(recfuel - 1, iadd(fid, 1), nfiles, ixf, ixs, ixp, ixb, start_ns, budget_ns)
      end
    end
  ) else 0

implement ix_step_all(vault, ixf, ixs, ixp, ixb, budget_ns) = let
  val nfiles = ix_file_count(ixf)
  val () = ix_bloom_ensure(ixb, nfiles)
  val start_ns = mono_ns()
in
  step_loop_m(airlock_nat(MAX_REC_FUEL), 0, nfiles, ixf, ixs, ixp, ixb, start_ns, budget_ns)
end
