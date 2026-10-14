#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_draft.sats"
staload "data_text/normalization_row.sats"
staload "data_text/normalization_pairs.sats"
staload "data_text/normalization_writer.sats"

fun limits {n:nat} .<n>. (n: int(n), draft: !NormalizationDraft, i: int, max_depth: int, max_expansion: int): @(int,int) =
  if n = 0 then @(max_depth,max_expansion) else let
    val row = normalization_draft_row(draft,i)
  in limits(n-1,draft,iadd(i,1),imax(max_depth,row.depth),imax(max_expansion,row.compatibility)) end

fun header(output: !Buf, draft: !NormalizationDraft, pairs: int): void = let
  val count = normalization_draft_count(draft)
  val @(depth,expansion) = limits(airlock_nat(count),draft,0,1,3)
  val () = buf_set32(output,0,NORMALIZATION_MAGIC)
  val () = buf_set32(output,1,NORMALIZATION_VERSION)
  val () = buf_set32(output,2,count)
  val () = buf_set32(output,3,normalization_draft_mappings(draft))
  val () = buf_set32(output,4,pairs)
  val () = buf_set32(output,5,expansion)
  val () = buf_set32(output,6,depth)
in buf_set32(output,7,0) end

fun rows {n:nat} .<n>. (n: int(n), draft: !NormalizationDraft, output: !Buf, i: int): void =
  if n = 0 then () else let
    val at = iadd(NORMALIZATION_HEADER_WORDS,imul(i,NORMALIZATION_ROW_WORDS))
    val () = normalization_row_write(output,at,normalization_draft_row(draft,i))
  in rows(n-1,draft,output,iadd(i,1)) end

fun mappings {n:nat} .<n>. (n: int(n), draft: !NormalizationDraft, output: !Buf, base: int, i: int): void =
  if n = 0 then () else let
    val () = buf_set32(output,iadd(base,i),normalization_draft_mapping(draft,i))
  in mappings(n-1,draft,output,base,iadd(i,1)) end

fun copy_pairs {n:nat} .<n>. (n: int(n), pairs: !Buf, output: !Buf, base: int, i: int): void =
  if n = 0 then () else let
    val () = buf_set32(output,iadd(base,i),buf_get32(pairs,i))
  in copy_pairs(n-1,pairs,output,base,iadd(i,1)) end

implement normalization_draft_write(draft,path) = let
  val n = normalization_draft_count(draft)
  val m = normalization_draft_mappings(draft)
  val pairs = normalization_draft_pairs(draft)
  val p = idiv(buf_len(pairs),12)
  val map_base = iadd(NORMALIZATION_HEADER_WORDS,imul(n,NORMALIZATION_ROW_WORDS))
  val pair_base = iadd(map_base,m)
  val size = imul(iadd(pair_base,imul(p,3)),4)
  val output = buf_make(size)
  val () = header(output,draft,p)
  val () = rows(airlock_nat(n),draft,output,0)
  val () = mappings(airlock_nat(m),draft,output,map_base,0)
  val () = copy_pairs(airlock_nat(imul(p,3)),pairs,output,pair_base,0)
  val () = buf_set_len(output,size)
  val written = fs_write_buf(path,output,size)
  val () = buf_free(output)
  val () = buf_free(pairs)
in ieq(written,1) end
