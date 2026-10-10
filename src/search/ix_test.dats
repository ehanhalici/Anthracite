#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "data_ast/doc.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tab.sats"
staload "search/ix_store.sats"
staload "search/ix_fold.sats"
staload "search/ix_query.sats"
staload "search/ix_build.sats"
staload "search/ix_match.sats"
staload "search/ix_test.sats"

fun test_turkish_fold(): bool = let
  var b1 = buf_make(16)
  val () = bstr(b1, "İSTANBUL")
  var b2 = buf_make(16)
  val () = bstr(b2, "ıstanbul")
  var f1 = buf_make(16)
  var o1 = buf_make(16)
  val l1 = buf_len(b1)
  val () = fold_range_buf(b1, 0, l1, f1, o1)
  var f2 = buf_make(16)
  var o2 = buf_make(16)
  val l2 = buf_len(b2)
  val () = fold_range_buf(b2, 0, l2, f2, o2)
  val eq = beq(f1, f2, 0)
  val () = buf_free(b1); val () = buf_free(b2)
  val () = buf_free(f1); val () = buf_free(o1)
  val () = buf_free(f2); val () = buf_free(o2)
in
  eq
end

fun test_query_parse(): bool = let
  var q = buf_make(32)
  val () = bstr(q, "#tag [[target")
  var pool = buf_make(32)
  var terms = buf_make(32)
  val n = ix_query_parse(q, pool, terms)
  val t0 = buf_get32(terms, 0)
  val t1 = buf_get32(terms, 4)
  val ok = ieq(n, 2) andalso ieq(t0, 1) andalso ieq(t1, 2)
  val () = buf_free(q)
  val () = buf_free(pool)
  val () = buf_free(terms)
in
  ok
end

fun test_bloom_trigram(): bool = let
  var ixb = buf_make(256)
  val () = ix_bloom_ensure(ixb, 1)
  val () = ix_bloom_set_trigram(ixb, 0, 97, 110, 116)
  val ok1 = ix_bloom_test_trigram(ixb, 0, 97, 110, 116)
  val ok2 = not(ix_bloom_test_trigram(ixb, 0, 120, 121, 122))
  val () = buf_free(ixb)
in
  ok1 andalso ok2
end

fun test_doc_find_and_reveal(): bool = let
  val doc = doc_open()
  val text = "## Baslik\nGizli metin burada\n"
  val () = doc_insert(doc, c_str_ptr(text), c_strlen(text))
  val () = doc_toggle(doc, 0)
  val c1 = is_on(doc_node_collapsed(doc, 0))
  val () = doc_reveal(doc, 15)
  val c2 = is_off(doc_node_collapsed(doc, 0))
  var q = buf_make(16)
  val () = bstr(q, "burada")
  val p = ix_doc_find(doc, q, 0, 1)
  val () = buf_free(q)
  val () = doc_free(doc)
in
  c1 andalso c2 andalso igt(p, 0)
end

fun setup_test_index(path: !Buf, text: string, ixf: &Buf >> _, ixs: &Buf >> _, ixp: &Buf >> _, ixb: &Buf >> _): void = let
  var body = buf_make(128)
  val () = bstr(body, text)
  val blen = buf_len(body)
  val _ = fs_write_buf(cstr(path), body, blen)
  val () = buf_free(body)
  val poff = buf_len(ixp)
  val plen = buf_len(path)
  val () = bcat(ixp, path, 0, plen)
  val fid = ix_file_add(ixf, poff, plen, 0, 0, 0, 0, 0, 0)
  val () = ix_bloom_ensure(ixb, 1)
  val doc = doc_open()
  val () = doc_insert(doc, c_str_ptr(text), c_strlen(text))
  val () = ix_extract_doc(doc, fid, ixs, ixp, ixb)
in
  doc_free(doc)
end

fun test_search_match(): bool = let
  var path = buf_make(32)
  val () = bstr(path, "/tmp/anth-s/test_match.md")
  val text = "# Proje\nBu belgede #onemli etiket ve [[Notlar]] var.\nAyrica İSTANBUL sehri.\n"
  var ixf = buf_make(64); var ixs = buf_make(64); var ixp = buf_make(64); var ixb = buf_make(256)
  val () = setup_test_index(path, text, ixf, ixs, ixp, ixb)
  var hits = buf_make(64); var hmeta = buf_make(64); var hjump = buf_make(64)
  var q = buf_make(16)
  val () = bstr(q, "ıstanbul")
  var hn: int = 0; var nfiles: int = 0; var partial: int = 0
  var vault = buf_make(4); val dummy_tabs = TNil()
  val () = ix_match_search(q, vault, dummy_tabs, ixf, ixs, ixp, ixb, hits, hmeta, hjump, hn, nfiles, partial)
  val ok = igt(hn, 0)
  val () = (tabs_free(dummy_tabs); buf_free(path); buf_free(ixf); buf_free(ixs); buf_free(ixp))
  val () = (buf_free(ixb); buf_free(hits); buf_free(hmeta); buf_free(hjump); buf_free(q); buf_free(vault))
in
  ok
end

implement ix_selftest() =
  if test_turkish_fold() andalso test_query_parse() andalso test_bloom_trigram() andalso test_doc_find_and_reveal() andalso test_search_match() then 1
  else 0
