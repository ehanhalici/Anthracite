staload "mem.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_db.sats"
staload "data_text/unicode_property.sats"
staload "data_text/line_types.sats"
staload "data_text/line_engine.sats"
fun wrong_domain(map: !PropertyMap(1),width: !PropertyMap(5),
  category: !PropertyMap(6),db: !UnicodeDb,text: !ScalarText): LineBreakMap =
  line_boundaries(map,width,category,db,text)
