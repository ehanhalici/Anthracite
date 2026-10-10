#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/doc.sats"
staload "data_ast/ast_dump.sats"

implement kind_name(k) = case+ k of
  | KNone() => "None"
  | KPara() => "Para"
  | KH1() => "H1" | KH2() => "H2" | KH3() => "H3" | KH4() => "H4" | KH5() => "H5" | KH6() => "H6"
  | KUl() => "Ul" | KOl() => "Ol" | KLi() => "Li"
  | KQuote() => "Quote" | KCode() => "Code" | KHr() => "Hr" | KTable() => "Table"
  | KText() => "Text" | KWiki() => "Wiki" | KEmbed() => "Embed" | KTag() => "Tag" | KTask() => "Task"
  | KFn() => "Fn" | KFndef() => "Fndef" | KHigh() => "High" | KMath() => "Math" | KMathb() => "Mathb" | KFm() => "Fm"
  | KImage() => "Image" | KTd() => "Td" | KBold() => "Bold" | KItalic() => "Italic" | KStrike() => "Strike" | KLink() => "Link"
  | KMark() => "Mark" | KRaw() => "Raw" | KInfo() => "Info" | KEscape() => "Escape" | KCodeSpan() => "CodeSpan" | KUrl() => "Url"
  | KHtmlBlock() => "HtmlBlock" | KHtmlInline() => "HtmlInline" | KBreak() => "Break" | KComment() => "Comment" | KBlockId() => "BlockId"
  | KCallout() => "Callout" | KCalloutHead() => "CalloutHead" | KTableRow() => "Row" | KTableCell() => "Cell" | KTableDelim() => "Delim"
  | KLinkDest() => "LinkDest" | KLinkTitle() => "LinkTitle" | KWikiTarget() => "WikiTarget" | KWikiHeading() => "WikiHeading"
  | KWikiBlock() => "WikiBlock" | KWikiAlias() => "WikiAlias" | KFnInline() => "FnInline" | KMathBlock() => "MathBlock"
  | KDirective() => "Directive"

implement kind_is_leaf(k) = case+ k of
  | KText() => true | KMark() => true | KRaw() => true | KInfo() => true
  | KEscape() => true | KTag() => true | KTask() => true | KFn() => true
  | KUrl() => true | KHtmlInline() => true | KBreak() => true | KBlockId() => true
  | KTableDelim() => true | KLinkDest() => true | KLinkTitle() => true
  | KWikiTarget() => true | KWikiHeading() => true | KWikiBlock() => true | KWikiAlias() => true
  | KHr() => true | KHtmlBlock() => true | KDirective() => true | KNone() => true
  | KTd() => true
  | KPara() => false | KH1() => false | KH2() => false | KH3() => false
  | KH4() => false | KH5() => false | KH6() => false | KUl() => false
  | KOl() => false | KLi() => false | KQuote() => false | KCode() => false
  | KTable() => false | KWiki() => false | KEmbed() => false | KFndef() => false
  | KHigh() => false | KMath() => false | KMathb() => false | KFm() => false
  | KImage() => false | KBold() => false | KItalic() => false | KStrike() => false
  | KLink() => false | KCodeSpan() => false | KComment() => false | KCallout() => false
  | KCalloutHead() => false | KTableRow() => false | KTableCell() => false | KFnInline() => false
  | KMathBlock() => false

implement kind_is_container(k) = not(kind_is_leaf(k))

implement kind_is_block(k) = case+ k of
  | KPara() => true | KH1() => true | KH2() => true | KH3() => true
  | KH4() => true | KH5() => true | KH6() => true | KUl() => true
  | KOl() => true | KLi() => true | KQuote() => true | KCode() => true
  | KHr() => true | KTable() => true | KFndef() => true | KFm() => true
  | KHtmlBlock() => true | KCallout() => true | KCalloutHead() => true
  | KTableRow() => true | KTableCell() => true | KTableDelim() => true
  | KMathBlock() => true | KDirective() => true
  | KNone() => false | KText() => false | KWiki() => false | KEmbed() => false
  | KTag() => false | KTask() => false | KFn() => false | KHigh() => false
  | KMath() => false | KMathb() => false | KImage() => false | KTd() => false
  | KBold() => false | KItalic() => false | KStrike() => false | KLink() => false
  | KMark() => false | KRaw() => false | KInfo() => false | KEscape() => false
  | KCodeSpan() => false | KUrl() => false | KHtmlInline() => false | KBreak() => false
  | KComment() => false | KBlockId() => false | KLinkDest() => false | KLinkTitle() => false
  | KWikiTarget() => false | KWikiHeading() => false | KWikiBlock() => false | KWikiAlias() => false
  | KFnInline() => false

fun dump_char(dst: &Buf >> _, c: int): void = buf_push(dst, c)

fun dump_str_m {rem:nat} .<rem>. (
  dst: &Buf >> _, s: string, rem: int(rem), i: int
): void =
  if rem > 0 then let
    val () = dump_char(dst, c_str_byte(s, i))
  in
    dump_str_m(dst, s, rem - 1, iadd(i, 1))
  end else ()

fun dump_str(dst: &Buf >> _, s: string): void = let
  val n = c_strlen(s)
in
  dump_str_m(dst, s, airlock_span(0, n), 0)
end

fun dump_digits {v:nat} .<v>. (dst: &Buf >> _, v: int(v)): void =
  if v > 0 then let
    val () = dump_digits(dst, v / 10)
  in
    dump_char(dst, iadd(48, imod(v, 10)))
  end else ()

fun dump_int(dst: &Buf >> _, v: int): void =
  if v < 0 then let
    val () = dump_char(dst, 126) (* ~ *)
    val pv = ~v
    val () = if pv = 0 then dump_char(dst, 48) else dump_digits(dst, airlock_nat(pv))
  in
  end else if v = 0 then dump_char(dst, 48)
  else dump_digits(dst, airlock_nat(v))

extern fun dump_children_exh(d: !Doc, c: int, dst: &Buf >> _): void = "mac#anth_die_void"
extern fun dump_node_exh(d: !Doc, i: int, dst: &Buf >> _): void = "mac#anth_die_void"

fun dump_children_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, c: int, dst: &Buf >> _, is_first: bool
): void =
  if recfuel > 0 then (
    if c < 0 orelse c >= doc_nnodes(d) then ()
    else let
      val () = if not(is_first) then dump_char(dst, 32) else ()
      val () = dump_node_m(recfuel - 1, d, c, dst)
      val next_c = doc_node_next_sib(d, c)
    in
      dump_children_m(recfuel - 1, d, next_c, dst, false)
    end
  ) else dump_children_exh(d, c, dst)

and dump_node_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, dst: &Buf >> _
): void =
  if recfuel > 0 then let
    val k = doc_node_kind(d, i)
    val () = dump_str(dst, kind_name(k))
    val () = dump_char(dst, 91)
    val () = dump_int(dst, doc_node_start(d, i))
    val () = dump_char(dst, 44)
    val () = dump_int(dst, doc_node_end(d, i))
    val () = dump_char(dst, 93)
    val fc = doc_node_first_child(d, i)
  in
    if fc >= 0 then let
      val () = dump_char(dst, 40)
      val () = dump_children_m(recfuel - 1, d, fc, dst, true)
      val () = dump_char(dst, 41)
    in
    end else ()
  end else dump_node_exh(d, i, dst)

extern fun dump_roots_exh(d: !Doc, i: int, n: int, dst: &Buf >> _, is_first: bool): void = "mac#anth_die_void"

fun dump_roots_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int, dst: &Buf >> _, is_first: bool
): void =
  if recfuel > 0 then (
    if i >= n then ()
    else if doc_node_parent(d, i) < 0 then let
      val () = if not(is_first) then dump_char(dst, 32) else ()
      val () = dump_node_m(recfuel - 1, d, i, dst)
    in
      dump_roots_m(recfuel - 1, d, iadd(i, 1), n, dst, false)
    end else dump_roots_m(recfuel - 1, d, iadd(i, 1), n, dst, is_first)
  ) else dump_roots_exh(d, i, n, dst, is_first)

implement ast_dump(d, dst) = let
  val n = doc_nnodes(d)
in
  if n > 0 then dump_roots_m(airlock_nat(MAX_REC_FUEL), d, 0, n, dst, true)
  else ()
end
