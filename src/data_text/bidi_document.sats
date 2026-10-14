staload "mem.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_property.sats"
staload "data_text/bidi_types.sats"
staload "data_text/bidi_bracket_data.sats"
staload "data_text/bidi_line.sats"
datavtype BidiDocument = BidiDocument of (Buf, Buf, Buf, int)
fun bidi_document_make(map: !PropertyMap(2), text: !ScalarText, brackets: !BidiBrackets, direction: ParagraphDirection): BidiDocument
fun bidi_document_count(document: !BidiDocument): int
fun bidi_document_level(document: !BidiDocument, i: int): int
fun bidi_document_base(document: !BidiDocument, i: int): int
fun bidi_document_paragraph_end(document: !BidiDocument, i: int): int
fun bidi_document_dispose(document: BidiDocument): void
(* Borrow paragraph levels; L1 changes only this line's temporary work buffer.
   The result maps visual positions to original source scalar indices. *)
fun bidi_document_line(document: !BidiDocument, map: !PropertyMap(2), text: !ScalarText, start: int, finish: int): BidiOrder

