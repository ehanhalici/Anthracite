staload "data_text/line_break/line_types.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/utf8/utf8.sats"
fun line_source_token(map: !PropertyMap(4),width: !PropertyMap(5),
  category: !PropertyMap(6),emoji: !UnicodeDb,cp: int,index: int): LineToken
fun line_unbound_mark(token: LineToken): LineToken
fun line_tokens_build(map: !PropertyMap(4),width: !PropertyMap(5),
  category: !PropertyMap(6),emoji: !UnicodeDb,text: !ScalarText): LineTokens
