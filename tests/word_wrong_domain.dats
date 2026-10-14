staload "mem.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_db.sats"
staload "data_text/unicode_property.sats"
staload "data_text/word_types.sats"
(* This file must fail at the static boundary, not at link/runtime. *)
fun wrong_domain(map: !PropertyMap(2), db: !UnicodeDb, text: !ScalarText): Buf =
  word_boundaries(map,db,text)

