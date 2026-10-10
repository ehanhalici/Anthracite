#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/doc.sats"
staload "data_ast/ast.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tab.sats"
staload "search/ix_store.sats"
staload "search/ix_fold.sats"
staload "search/ix_query.sats"
staload "flag.sats"
staload "search/ix_build.sats"
staload "search/ix_match.sats"

fun iand(a: int, n: int): int = anth_iand(a, n)

fun buf_push32(b: &Buf >> _, v: int): void = let
  val n = buf_len(b)
  val idx = idiv(n, 4)
  val need = iadd(n, 4)
  val () = if buf_cap(b) < need then buf_resize(b, imax(16, imul(need, 2))) else ()
  val () = buf_set_len(b, need)
  val () = buf_set32(b, idx, v)
in
end

fun push_jump(hjump: &Buf >> _, fid: int, line: int, col: int): void = (
  buf_push32(hjump, fid);
  buf_push32(hjump, line);
  buf_push32(hjump, col)
)

fun push_header(hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, path: !Buf, line: int): void = let
  val () = buf_ensure(hmeta, imul(iadd(hn, 2), 16))
  val () = buf_set32(hmeta, imul(hn, 4), ~1)
  val plen = buf_len(path)
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 1), buf_len(hits))
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 2), plen)
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 3), line)
  val () = bcat(hits, path, 0, plen)
in
  hn := iadd(hn, 1)
end

fun push_hit(hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, b: !Buf, qlen: int, ls: int, le: int, at: int): void = let
  val () = buf_ensure(hmeta, imul(iadd(hn, 1), 16))
  val () = buf_set32(hmeta, imul(hn, 4), isub(at, ls))
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 1), buf_len(hits))
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 2), isub(le, ls))
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 3), qlen)
  val () = bcat(hits, b, ls, le)
in
  hn := iadd(hn, 1)
end

fun bloom_check_term(ixb: !Buf, fid: int, pool: !Buf, toff: int, tlen: int): bool =
  if ilt(tlen, 3) then true
  else let
    val b0 = buf_get(pool, toff)
    val b1 = buf_get(pool, iadd(toff, 1))
    val b2 = buf_get(pool, iadd(toff, 2))
  in
    ix_bloom_test_trigram(ixb, fid, b0, b1, b2)
  end

fun bloom_check_terms_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ixb: !Buf, fid: int, pool: !Buf, terms: !Buf, ti: int, nterms: int): bool =
  if recfuel > 0 then (
    if ige(ti, nterms) then true
    else let
      val op_c = buf_get32(terms, imul(ti, 4))
      val toff = buf_get32(terms, iadd(imul(ti, 4), 1))
      val tlen = buf_get32(terms, iadd(imul(ti, 4), 2))
    in
      if op_c != 0 then bloom_check_terms_m(recfuel - 1, ixb, fid, pool, terms, iadd(ti, 1), nterms)
      else if not(bloom_check_term(ixb, fid, pool, toff, tlen)) then false
      else bloom_check_terms_m(recfuel - 1, ixb, fid, pool, terms, iadd(ti, 1), nterms)
    end
  ) else true

fun buf_find_sub_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), haystack: !Buf, hlen: int, hp: int, needle: !Buf, nlen: int, np: int): int =
  if recfuel > 0 then (
    if ige(np, nlen) then isub(hp, nlen)
    else if ige(hp, hlen) then ~1
    else if ieq(buf_get(haystack, hp), buf_get(needle, np)) then
      buf_find_sub_m(recfuel - 1, haystack, hlen, iadd(hp, 1), needle, nlen, iadd(np, 1))
    else
      buf_find_sub_m(recfuel - 1, haystack, hlen, iadd(isub(hp, np), 1), needle, nlen, 0)
  ) else ~1

fun buf_find_sub(haystack: !Buf, hlen: int, needle: !Buf, nlen: int): int =
  if ilt(hlen, nlen) then ~1
  else if ieq(nlen, 0) then 0
  else buf_find_sub_m(airlock_nat(MAX_REC_FUEL), haystack, hlen, 0, needle, nlen, 0)

fun match_line_term(fline: !Buf, flen: int, pool: !Buf, toff: int, tlen: int): int = let
  var nbuf = buf_make(iadd(tlen, 1))
  val () = bcat(nbuf, pool, toff, iadd(toff, tlen))
  val pos = buf_find_sub(fline, flen, nbuf, tlen)
  val () = buf_free(nbuf)
in
  pos
end

fun match_line_all_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), fline: !Buf, flen: int, pool: !Buf, terms: !Buf, ti: int, nterms: int, first_pos: &int >> _): bool =
  if recfuel > 0 then (
    if ige(ti, nterms) then true
    else let
      val op_c = buf_get32(terms, imul(ti, 4))
      val toff = buf_get32(terms, iadd(imul(ti, 4), 1))
      val tlen = buf_get32(terms, iadd(imul(ti, 4), 2))
    in
      if op_c != 0 then match_line_all_m(recfuel - 1, fline, flen, pool, terms, iadd(ti, 1), nterms, first_pos)
      else let
        val pos = match_line_term(fline, flen, pool, toff, tlen)
      in
        if ilt(pos, 0) then false
        else let
          val () = if ilt(first_pos, 0) then first_pos := pos else ()
        in
          match_line_all_m(recfuel - 1, fline, flen, pool, terms, iadd(ti, 1), nterms, first_pos)
        end
      end
    end
  ) else true

fun push_matched_hit(d: !Doc, fid: int, path: !Buf, line: int, ls: int, le: int, terms: !Buf, orig_col: int, hits: &Buf >> _, hmeta: &Buf >> _, hjump: &Buf >> _, hn: &int >> _, hfile: &int >> _, headed: &int >> _): void = let
  val () = if ieq(headed, 0) then (push_header(hits, hmeta, hn, path, ~1); push_jump(hjump, fid, 0, 0); headed := 1) else ()
  val qlen = buf_get32(terms, 2)
  var raw_line = buf_make(iadd(isub(le, ls), 1))
  var raw_omap = buf_make(4)
  val () = fold_range_doc(d, ls, le, raw_line, raw_omap)
  val rlen = buf_len(raw_line)
  val () = push_hit(hits, hmeta, hn, raw_line, qlen, 0, rlen, orig_col)
  val () = push_jump(hjump, fid, line, orig_col)
  val () = buf_free(raw_line)
  val () = buf_free(raw_omap)
in
  hfile := iadd(hfile, 1)
end

fun get_col_offset(omap: !Buf, first_pos: int, ls: int): int = let
  val olen = idiv(buf_len(omap), 4)
in
  if ilt(first_pos, olen) then isub(buf_get32(omap, first_pos), ls)
  else first_pos
end

fun scan_one_line(d: !Doc, fid: int, path: !Buf, line: int, nlines: int, pool: !Buf, terms: !Buf, nterms: int, hits: &Buf >> _, hmeta: &Buf >> _, hjump: &Buf >> _, hn: &int >> _, hfile: &int >> _, headed: &int >> _): void = let
  val ls = doc_line_start(d, line)
  val le = if ilt(iadd(line, 1), nlines) then doc_line_start(d, iadd(line, 1)) else doc_len(d)
  var fline = buf_make(64)
  var omap = buf_make(64)
  val () = fold_range_doc(d, ls, le, fline, omap)
  val flen = buf_len(fline)
  var first_pos: int = ~1
  val matched = match_line_all_m(airlock_nat(MAX_REC_FUEL), fline, flen, pool, terms, 0, nterms, first_pos)
  val orig_col = get_col_offset(omap, first_pos, ls)
  val () = buf_free(fline)
  val () = buf_free(omap)
in
  if matched andalso ige(first_pos, 0) then
    push_matched_hit(d, fid, path, line, ls, le, terms, orig_col, hits, hmeta, hjump, hn, hfile, headed)
  else ()
end

fun scan_doc_lines_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, fid: int, path: !Buf, nlines: int, line: int, pool: !Buf, terms: !Buf, nterms: int, hits: &Buf >> _, hmeta: &Buf >> _, hjump: &Buf >> _, hn: &int >> _, hfile: &int >> _, headed: &int >> _): void =
  if recfuel > 0 then (
    if ige(line, nlines) orelse ige(hfile, MAX_HITS_PER_FILE) orelse ige(hn, MAX_SEARCH_HITS) then ()
    else let
      val () = scan_one_line(d, fid, path, line, nlines, pool, terms, nterms, hits, hmeta, hjump, hn, hfile, headed)
    in
      scan_doc_lines_m(recfuel - 1, d, fid, path, nlines, iadd(line, 1), pool, terms, nterms, hits, hmeta, hjump, hn, hfile, headed)
    end
  ) else ()

fun populate_doc_from_tab(doc: !Doc, tab_text: !Buf): void =
  doc_insert(doc, buf_ptr(tab_text), buf_len(tab_text))

fun load_match_doc(doc: !Doc, path: !Buf, tabs: !Tabs): bool = let
  var tab_text = buf_make(64)
  val found = tabs_copy_doc_text(tabs, path, tab_text)
in
  if found > 0 then let
    val () = populate_doc_from_tab(doc, tab_text)
    val () = buf_free(tab_text)
  in
    true
  end else let
    val () = buf_free(tab_text)
  in
    doc_load(doc, cstr(path))
  end
end

fun match_file_content(path: !Buf, fid: int, tabs: !Tabs, pool: !Buf, terms: !Buf, nterms: int, hits: &Buf >> _, hmeta: &Buf >> _, hjump: &Buf >> _, hn: &int >> _): int = let
  val doc = doc_open()
  val ok = load_match_doc(doc, path, tabs)
in
  if ok then let
    var hfile: int = 0
    var headed: int = 0
    val nlines = doc_nlines(doc)
    val () = scan_doc_lines_m(airlock_nat(MAX_REC_FUEL), doc, fid, path, nlines, 0, pool, terms, nterms, hits, hmeta, hjump, hn, hfile, headed)
    val () = doc_free(doc)
  in
    hfile
  end else (doc_free(doc); 0)
end

fun match_files_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), fid: int, nfiles: int, tabs: !Tabs, ixf: !Buf, ixp: !Buf, ixb: !Buf, pool: !Buf, terms: !Buf, nterms: int, hits: &Buf >> _, hmeta: &Buf >> _, hjump: &Buf >> _, hn: &int >> _, nfiles_hit: &int >> _, is_partial: &int >> _): void =
  if recfuel > 0 then (
    if ige(fid, nfiles) orelse ige(hn, MAX_SEARCH_HITS) then (
      if ige(hn, MAX_SEARCH_HITS) andalso ilt(fid, nfiles) then is_partial := 1 else ()
    ) else let
      val st = ix_file_get(ixf, fid, IX_F_STATE)
    in
      if ieq(st, 2) then match_files_m(recfuel - 1, iadd(fid, 1), nfiles, tabs, ixf, ixp, ixb, pool, terms, nterms, hits, hmeta, hjump, hn, nfiles_hit, is_partial)
      else let
        val bloom_ok = bloom_check_terms_m(airlock_nat(MAX_REC_FUEL), ixb, fid, pool, terms, 0, nterms)
      in
        if not(bloom_ok) then match_files_m(recfuel - 1, iadd(fid, 1), nfiles, tabs, ixf, ixp, ixb, pool, terms, nterms, hits, hmeta, hjump, hn, nfiles_hit, is_partial)
        else let
          val poff = ix_file_get(ixf, fid, IX_F_PATHOFF)
          val plen = ix_file_get(ixf, fid, IX_F_PATHLEN)
          var path = buf_make(iadd(plen, 1))
          val () = bcat(path, ixp, poff, iadd(poff, plen))
          val cnt = match_file_content(path, fid, tabs, pool, terms, nterms, hits, hmeta, hjump, hn)
          val () = buf_free(path)
          val () = if igt(cnt, 0) then nfiles_hit := iadd(nfiles_hit, 1) else ()
        in
          match_files_m(recfuel - 1, iadd(fid, 1), nfiles, tabs, ixf, ixp, ixb, pool, terms, nterms, hits, hmeta, hjump, hn, nfiles_hit, is_partial)
        end
      end
    end
  ) else ()

implement ix_match_search(q, vault, tabs, ixf, ixs, ixp, ixb, hits, hmeta, hjump, hn, nfiles_hit, is_partial) = let
  var pool = buf_make(64)
  var terms = buf_make(64)
  val nterms = ix_query_parse(q, pool, terms)
  val nfiles = ix_file_count(ixf)
in
  if igt(nterms, 0) then let
    val () = match_files_m(airlock_nat(MAX_REC_FUEL), 0, nfiles, tabs, ixf, ixp, ixb, pool, terms, nterms, hits, hmeta, hjump, hn, nfiles_hit, is_partial)
    val () = buf_free(pool)
    val () = buf_free(terms)
  in
  end else (buf_free(pool); buf_free(terms))
end

fun check_match_at(d: !Doc, p: int, q: !Buf, qlen: int): bool = let
  var fbuf = buf_make(iadd(qlen, 1))
  var omap = buf_make(iadd(qlen, 1))
  val () = fold_range_doc(d, p, iadd(p, qlen), fbuf, omap)
  var qbuf = buf_make(iadd(qlen, 1))
  var qomap = buf_make(iadd(qlen, 1))
  val () = fold_range_buf(q, 0, qlen, qbuf, qomap)
  val fl = buf_len(fbuf)
  val ql = buf_len(qbuf)
  val pos = buf_find_sub(fbuf, fl, qbuf, ql)
  val () = buf_free(fbuf)
  val () = buf_free(omap)
  val () = buf_free(qbuf)
  val () = buf_free(qomap)
in
  ige(pos, 0)
end

fun find_fwd_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, dlen: int, p: int, q: !Buf, qlen: int): int =
  if recfuel > 0 then (
    if igt(iadd(p, qlen), dlen) then ~1
    else if check_match_at(d, p, q, qlen) then p
    else find_fwd_m(recfuel - 1, d, dlen, iadd(p, 1), q, qlen)
  ) else ~1

fun find_bwd_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, q: !Buf, qlen: int): int =
  if recfuel > 0 then (
    if ilt(p, 0) then ~1
    else if check_match_at(d, p, q, qlen) then p
    else find_bwd_m(recfuel - 1, d, isub(p, 1), q, qlen)
  ) else ~1

fun find_sub_doc(d: !Doc, dlen: int, from_pos: int, q: !Buf, qlen: int, dir: int): int =
  if igt(dir, 0) then find_fwd_m(airlock_nat(MAX_REC_FUEL), d, dlen, from_pos, q, qlen)
  else find_bwd_m(airlock_nat(MAX_REC_FUEL), d, from_pos, q, qlen)

implement ix_doc_find(d, q, from_pos, dir) = let
  val dlen = doc_len(d)
  val qlen = buf_len(q)
in
  if ilt(dlen, qlen) orelse ieq(qlen, 0) then ~1
  else find_sub_doc(d, dlen, from_pos, q, qlen, dir)
end

fun reveal_loop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int, off: int): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val k = doc_node_kind(d, i)
      val st = doc_node_start(d, i)
    in
      if is_heading(k) andalso is_on(doc_node_collapsed(d, i)) andalso igt(off, st) then let
        val () = doc_toggle(d, i)
      in
        reveal_loop_m(recfuel - 1, d, iadd(i, 1), n, off)
      end else
        reveal_loop_m(recfuel - 1, d, iadd(i, 1), n, off)
    end
  ) else ()

implement doc_reveal(d, off) =
  reveal_loop_m(airlock_nat(MAX_REC_FUEL), d, 0, doc_nnodes(d), off)
