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
staload "data_text/bidi_line.sats"
extern fun document_invalid_line(): BidiOrder = "mac#anth_die_box"

fun copy_levels {n:nat} .<n>. (
  n: int(n), document: !BidiDocument, work: !BidiWork, i: int
): void = if n = 0 then () else let
  val source = bidi_source_index(work,i)
  val () = bidi_set_level(work,i,bidi_document_level(document,source))
in copy_levels(n-1,document,work,iadd(i,1)) end

fun source_indices {n:nat} .<n>. (n: int(n), order: !BidiOrder, i: int, start: int): void =
  if n = 0 then () else let
    val+ BidiOrder(indices,total) = order
    val () = buf_set32(indices,i,iadd(start,buf_get32(indices,i)))
  in source_indices(n-1,order,iadd(i,1),start) end

fun line_valid(document: !BidiDocument, text: !ScalarText, start: int, finish: int): bool =
  ieq(bidi_document_count(document),scalar_count(text)) andalso ige(start,0) andalso ige(finish,start)
  andalso ile(finish,bidi_document_count(document))
  andalso (ieq(start,finish) orelse ile(finish,bidi_document_paragraph_end(document,start)))

implement bidi_document_line(document,map,text,start,finish) =
  if not(line_valid(document,text,start,finish)) then document_invalid_line()
  else let
    val work = bidi_make_range(map,text,start,finish)
    val n = bidi_count(work)
    val () = copy_levels(airlock_nat(n),document,work,0)
    val base = if ieq(n,0) then 0 else bidi_document_base(document,start)
    val () = bidi_line_reset(work,0,n,base)
    val order = bidi_line_order(work,0,n)
    val () = source_indices(airlock_nat(bidi_order_count(order)),order,0,start)
    val () = bidi_dispose(work)
  in order end

