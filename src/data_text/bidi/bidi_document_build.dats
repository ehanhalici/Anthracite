#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/bidi/bidi_bracket_data.sats"
staload "data_text/bidi/bidi_resolution.sats"
staload "data_text/bidi/bidi_document.sats"
staload "data_text/bidi/bidi_predicates.sats"
extern fun paragraph_scan_exhausted(): int = "mac#anth_die_int"

fun paragraph_end {n:nat} .<n>. (n: int(n), map: !PropertyMap(2), text: !ScalarText, i: int): int =
  if ige(i,scalar_count(text)) then i else if n = 0 then paragraph_scan_exhausted() else let
    val cp = scalar_value(text,i)
    val kind = bidi_class_of(property_value(map,cp))
    val following = iadd(i,1)
    val crlf = ieq(cp,13) andalso ilt(following,scalar_count(text)) andalso ieq(scalar_value(text,following),10)
  in if bidi_is_paragraph_separator(kind) then iadd(following,if crlf then 1 else 0)
    else paragraph_end(n-1,map,text,following) end

fun store_paragraph {n:nat} .<n>. (
  n: int(n), document: !BidiDocument, work: !BidiWork, i: int, finish: int, base: int
): void = if n = 0 then () else let
  val+ BidiDocument(levels,bases,ends,total) = document
  val source = bidi_source_index(work,i)
  val () = buf_set(levels,source,bidi_level(work,i))
  val () = buf_set(bases,source,base)
  val () = buf_set32(ends,source,finish)
in store_paragraph(n-1,document,work,iadd(i,1),finish,base) end

fun build_paragraph(
  document: !BidiDocument, map: !PropertyMap(2), text: !ScalarText,
  brackets: !BidiBrackets, direction: ParagraphDirection, start: int
): int = let
  val finish = paragraph_end(airlock_nat(iadd(isub(scalar_count(text),start),1)),map,text,start)
  val work = bidi_make_range(map,text,start,finish)
  val base = bidi_resolve(work,text,brackets,direction)
  val () = store_paragraph(airlock_nat(bidi_count(work)),document,work,0,finish,base)
  val () = bidi_dispose(work)
in finish end

fun build_all {n:nat} .<n>. (
  n: int(n), document: !BidiDocument, map: !PropertyMap(2), text: !ScalarText,
  brackets: !BidiBrackets, direction: ParagraphDirection, start: int
): void = if ige(start,scalar_count(text)) then () else if n = 0 then let
    val stop = paragraph_scan_exhausted()
  in () end else let
    val finish = build_paragraph(document,map,text,brackets,direction,start)
  in build_all(n-1,document,map,text,brackets,direction,finish) end

implement bidi_document_make(map,text,brackets,direction) = let
  val n = scalar_count(text)
  val levels = buf_make(n)
  val bases = buf_make(n)
  val ends = buf_make(imul(n,4))
  val document = BidiDocument(levels,bases,ends,n)
  val () = build_all(airlock_nat(iadd(n,1)),document,map,text,brackets,direction,0)
in document end
