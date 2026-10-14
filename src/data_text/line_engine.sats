staload "data_text/unicode_property.sats"
staload "data_text/unicode_db.sats"
staload "data_text/utf8.sats"
staload "data_text/line_types.sats"
(* UAX #14 opportunities, not width-dependent wrapping. Index i is before
   source scalar i; n is the end-of-text mandatory boundary. *)
fun line_boundaries(map: !PropertyMap(4),width: !PropertyMap(5),
  category: !PropertyMap(6),emoji: !UnicodeDb,text: !ScalarText): LineBreakMap
