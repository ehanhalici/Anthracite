#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_property.sats"
staload "data_text/bidi_bracket_data.sats"
staload "data_text/bidi_resolution.sats"
staload "data_text/bidi_document.sats"

implement bidi_document_count(document) = let val+ BidiDocument(levels,bases,ends,n) = document in n end
implement bidi_document_level(document,i) = let val+ BidiDocument(levels,bases,ends,n) = document in buf_get(levels,i) end
implement bidi_document_base(document,i) = let val+ BidiDocument(levels,bases,ends,n) = document in buf_get(bases,i) end
implement bidi_document_paragraph_end(document,i) = let val+ BidiDocument(levels,bases,ends,n) = document in buf_get32(ends,i) end
implement bidi_document_dispose(document) = let
  val+ ~BidiDocument(levels,bases,ends,n) = document
  val () = buf_free(levels)
  val () = buf_free(bases)
in buf_free(ends) end

