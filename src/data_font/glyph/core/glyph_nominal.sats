staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
(* One immutable face per itemized run. This does not choose fonts, normalize,
   shape or visually reorder text. Scalars/spans come from the strict decoder;
   cluster IDs are original byte starts of extended grapheme clusters. Missing
   cmap entries remain glyph 0, for the selected face's actual .notdef raster. *)
fun glyph_nominal_read(face: !SfntFace,db: !UnicodeDb,text: !ScalarText,font: int,mask: uint): GlyphRunCreated
(* Owner bridge: info was validated against these immutable face bytes. *)
fun glyph_nominal_read_bytes(b: !Buf,info: SfntInfo,db: !UnicodeDb,text: !ScalarText,font: int,mask: uint): GlyphRunCreated
