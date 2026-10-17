staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/line_break/line_engine.sats"
fun wrong_domain(map: !PropertyMap(1),width: !PropertyMap(5),
  category: !PropertyMap(6),db: !UnicodeDb,text: !ScalarText): LineBreakMap =
  line_boundaries(map,width,category,db,text)
