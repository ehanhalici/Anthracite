#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_draft.sats"
staload "normalization_contracts.sats"
staload "data_text/normalization_row.sats"
staload "data_text/normalization_source.sats"
staload "data_text/normalization_graph.sats"
staload "data_text/normalization_graph_build.sats"

fun bytes(value: string): Buf = let
  val size = c_strlen(value)
  var result = buf_make(iadd(size,1))
  val () = buf_append(result,c_str_ptr(value),size)
in result end

fun rejected(value: string): int = let
  val source = bytes(value)
  val result = normalization_source(source)
  val () = buf_free(source)
in case+ result of
  | ~DraftRejected(error) => 0
  | ~DraftLoaded(draft) => let val () = normalization_draft_dispose(draft) in 1 end end

fun cycle(): int = let
  val source = bytes("0041;A;Lu;0;L;0042;;;;N;;;;;\n0042;B;Lu;0;L;0041;;;;N;;;;;\n")
  val result = normalization_source(source)
  val () = buf_free(source)
in case+ result of
  | ~DraftRejected(error) => 1
  | ~DraftLoaded(draft) => let
      val acyclic = normalization_draft_graph(draft)
      val () = normalization_draft_dispose(draft)
    in if acyclic then 1 else 0 end end

fun expansion_chain(): int = let
  val source = bytes("0041;A;Lu;0;L;0042 0042;;;;N;;;;;\n0042;B;Lu;0;L;0043 0043;;;;N;;;;;\n0300;MARK;Mn;230;NSM;;;;;N;;;;;\n")
  val result = normalization_source(source)
  val () = buf_free(source)
in case+ result of
  | ~DraftRejected(error) => 1
  | ~DraftLoaded(draft) => let
      val valid = normalization_draft_graph(draft)
      val first = normalization_draft_row(draft,0)
      val correct = valid andalso ieq(first.canonical,4) andalso ieq(first.compatibility,4)
      val () = normalization_draft_dispose(draft)
    in if correct then 0 else 1 end end

fun doubling_rows {n:nat} .<n>. (n: int(n), rows: !Buf, maps: !Buf, i: int): void =
  if n = 0 then () else let
    val cp = iadd(256,i)
    val at = imul(i,2)
    val row = @{cp=cp,ccc=0,kind=CanonicalMapping(),offset=at,count=2,depth=0,canonical=0,compatibility=0,excluded=false}
    val () = normalization_row_write(rows,imul(i,NORMALIZATION_ROW_WORDS),row)
    val () = buf_set32(maps,at,iadd(cp,1))
    val () = buf_set32(maps,iadd(at,1),iadd(cp,1))
  in doubling_rows(n-1,rows,maps,iadd(i,1)) end

fun expansion_overflow(): int = let
  val rows = buf_make(imul(imul(31,NORMALIZATION_ROW_WORDS),4))
  val maps = buf_make(248)
  val () = doubling_rows(31,rows,maps,0)
  val draft = NormalizationDraft(rows,maps,31,62)
  val accepted = normalization_draft_graph(draft)
  val () = normalization_draft_dispose(draft)
in if accepted then 1 else 0 end

implement normalization_source_contracts() =
  rejected("0041;A;Lu;999;L;0042;;;;N;;;;;\n")
  + rejected("0041;A;Lu;0;L;<unknown> 0042;;;;N;;;;;\n")
  + rejected("0041;A;Lu;0;L;<font> D800;;;;N;;;;;\n")
  + rejected("0041;A;Lu;0;L;ZZZZ;;;;N;;;;;\n")
  + rejected("AC00;HANGUL;Lo;0;L;0042;;;;N;;;;;\n")
  + cycle() + expansion_chain() + expansion_overflow()
