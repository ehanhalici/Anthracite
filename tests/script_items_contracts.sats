staload "data_text/script_data_types.sats"
staload "data_text/unicode_db.sats"
staload "data_text/unicode_property.sats"
staload "data_text/bidi_bracket_data.sats"
fun script_items_test_cases(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),brackets: !BidiBrackets): int
fun script_items_test_stress(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),brackets: !BidiBrackets): int
fun script_items_test_rejections(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),brackets: !BidiBrackets): int
