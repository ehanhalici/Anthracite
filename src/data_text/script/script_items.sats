staload "data_text/script/script_data_types.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/script/script_types.sats"
staload "data_text/script/script_items_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/bidi/bidi_bracket_data.sats"
(* Assign one resolved script per extended grapheme cluster. Common/Inherited
   resolve by surrounding candidate intersections, not Unicode-block heuristics.
   Paired brackets keep their enclosing script and reset at paragraph boundaries.
   This itemizes scripts; it does not shape, choose a font or reorder text. *)
fun script_items_make(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),
  text: !ScalarText,brackets: !BidiBrackets): ScriptItemsRead
fun script_items_budget(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),
  text: !ScalarText,brackets: !BidiBrackets,remaining: &int >> int): ScriptItemsRead
fun script_items_code(items: !ScriptItems,index: int): ScriptCode
fun script_items_count(items: !ScriptItems): int
fun script_items_dispose(items: ScriptItems): void
