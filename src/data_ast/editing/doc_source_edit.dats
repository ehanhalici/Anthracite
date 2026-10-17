#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/editing/doc_source_edit.sats"
staload "data_font/resources/font.sats"
staload "data_font/text/font_text.sats"
staload "data_font/native/ownership/font_source_grapheme.sats"
staload "data_text/grapheme/source_grapheme.sats"
extern fun exhausted(): int = "mac#anth_die_int"
fun failed(): SourceBoundaries = let val n=exhausted()
in @{previous=n,lower=n,upper=n,next=n} end
fun absolute(b: SourceBoundaries,start: int): SourceBoundaries =
  @{previous=iadd(start,b.previous),lower=iadd(start,b.lower),upper=iadd(start,b.upper),next=iadd(start,b.next)}
fun line_query(f: !Font,d: !Doc,line: int,at: int,scratch: &Buf >> _): SourceBoundaries = let
  val start=doc_line_start(d,line)
  val stop=if ilt(iadd(line,1),doc_nlines(d)) then doc_line_start(d,iadd(line,1)) else doc_len(d)
  val n=isub(stop,start) val ()=buf_ensure(scratch,n)
  val copied=doc_slice_buf(d,start,stop,scratch,n) val ()=buf_set_len(scratch,copied)
in case+ font_source_grapheme_query(f,scratch,n,isub(at,start)) of
  | ~None_vt() => failed() | ~Some_vt(b) => absolute(b,start) end
fun boundaries(f: !Font,d: !Doc,at: int,scratch: &Buf >> _): SourceBoundaries = let
  val line=doc_line_of(d,at) val b=line_query(f,d,line,at,scratch)
in if igt(line,0) andalso ieq(at,doc_line_start(d,line)) then let
  val prev=line_query(f,d,isub(line,1),at,scratch)
  in @{previous=prev.previous,lower=b.lower,upper=b.upper,next=b.next} end else b end
datatype EraseDirection = EraseBefore | EraseAfter
fun erase(f: !Font,d: !Doc,direction: EraseDirection,scratch: &Buf >> _): void = let
  val c=doc_caret(d) val a=doc_anchor(d)
  val lo=boundaries(f,d,imin(c,a),scratch)
  val hi=boundaries(f,d,imax(c,a),scratch)
  val start=if ine(c,a) orelse ine(lo.lower,lo.upper) then lo.lower else
    case+ direction of | EraseBefore() => lo.previous | EraseAfter() => lo.lower
  val stop=if ine(c,a) orelse ine(hi.lower,hi.upper) then hi.upper else
    case+ direction of | EraseAfter() => hi.next | EraseBefore() => hi.upper
in doc_delete_range(d,start,stop) end
fun apply(f: !Font,d: !Doc,edit: SourceEdit,scratch: &Buf >> _): void = let
  val c=doc_caret(d) val a=doc_anchor(d)
in case+ edit of
  | SourceLeft() => let val b=boundaries(f,d,imin(c,a),scratch)
    in doc_set_caret_move(d,if ine(c,a) then b.lower else b.previous) end
  | SourceRight() => let val b=boundaries(f,d,imax(c,a),scratch)
    in doc_set_caret_move(d,if ine(c,a) then b.upper else b.next) end
  | SourceSelectLeft() => let val b=boundaries(f,d,c,scratch) in doc_set_caret_extend(d,b.previous) end
  | SourceSelectRight() => let val b=boundaries(f,d,c,scratch) in doc_set_caret_extend(d,b.next) end
  | SourceBackspace() => erase(f,d,EraseBefore(),scratch) | SourceDelete() => erase(f,d,EraseAfter(),scratch) end
implement doc_source_edit(f,d,edit,scratch) =
  if not(font_text_active(f)) then false else let val ()=apply(f,d,edit,scratch) in true end
