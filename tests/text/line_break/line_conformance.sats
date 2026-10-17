staload "data_text/unicode/unicode_property.sats"
staload "data_text/unicode/unicode_db.sats"
typedef LineSummary = @{cases=int,errors=int}
fun line_check_file(map: !PropertyMap(4),width: !PropertyMap(5),
  category: !PropertyMap(6),emoji: !UnicodeDb,path: string): LineSummary
