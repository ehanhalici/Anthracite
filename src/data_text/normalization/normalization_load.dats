#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/source/text_source.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_validation.sats"
staload "data_text/normalization/normalization_errors.sats"
staload "data_text/normalization/normalization_load.sats"
staload "data_text/normalization/normalization_data.sats"

fun reject(bytes: Buf, error: NormalizationError): NormalizationLoad = let
  val () = buf_free(bytes)
in NormalizationRejected(error) end

fun dense_clear{n:nat} .<n>. (n: int(n),b: !Buf,at: int): void =
  if n = 0 then () else let val ()=buf_set32(b,at,~1) in dense_clear(n-1,b,iadd(at,1)) end
fun dense_rows{n:nat} .<n>. (n: int(n),b: !Buf,row: int,base: int): void =
  if n = 0 then () else let
    val cp=buf_get32(b,iadd(NORMALIZATION_HEADER_WORDS,imul(row,NORMALIZATION_ROW_WORDS)))
  in if ige(cp,UNICODE_DENSE_SCALARS) orelse ilt(cp,0) then ()
    else let val ()=buf_set32(b,iadd(base,cp),row) in dense_rows(n-1,b,iadd(row,1),base) end end
(* Row index (or ~1) per dense scalar, appended after the validated data;
   normalization_data.dats finds it from the buffer length. *)
fun with_dense(b0: Buf,header: NormalizationHeader): Buf = let
  var b: Buf=b0
  val base=idiv(buf_len(b),WORD32_BYTES)
  val bytes=imul(iadd(base,UNICODE_DENSE_SCALARS),WORD32_BYTES)
  val ()=buf_ensure(b,bytes) val ()=buf_set_len(b,bytes)
  val ()=dense_clear(airlock_nat(UNICODE_DENSE_SCALARS),b,base)
  val ()=dense_rows(airlock_nat(header.rows),b,0,base)
in b end
fun graph_check(bytes: Buf, header: NormalizationHeader): NormalizationLoad = let
  val data = NormalizationData(with_dense(bytes,header),header)
  val valid = normalization_graph_valid(data) andalso normalization_pairs_valid(data)
in if valid then NormalizationLoaded(data) else let
    val () = normalization_dispose(data)
  in NormalizationRejected(NormGraph()) end end

implement normalization_parse(bytes) = let
  val header = normalization_header_read(bytes)
in if not(normalization_header_valid(bytes,header)) then reject(bytes,NormHeader())
  else if not(normalization_structure_valid(bytes,header)) then reject(bytes,NormRanges())
  else graph_check(bytes,header) end

implement normalization_load(path) = case+ text_file_read(path) of
  | ~TextFileError(code) => NormalizationRejected(NormIo(code))
  | ~TextFile(bytes) => normalization_parse(bytes)
