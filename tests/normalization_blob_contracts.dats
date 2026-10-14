#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/text_source.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_validation.sats"
staload "normalization_contracts.sats"
staload "data_text/normalization_row.sats"
staload "data_text/normalization_load.sats"
staload "data_text/normalization_data.sats"
datatype Corruption = VersionCorruption | SizeCorruption | KindCorruption | FlagCorruption | RangeCorruption | ScalarCorruption | CycleCorruption | ExpansionCorruption

fun corrupt(bytes: !Buf, kind: Corruption): void = case+ kind of
  | VersionCorruption() => buf_set32(bytes,1,170000)
  | SizeCorruption() => buf_set32(bytes,2,2147483647)
  | KindCorruption() => buf_set32(bytes,10,3)
  | FlagCorruption() => buf_set32(bytes,16,2)
  | RangeCorruption() => buf_set32(bytes,11,1)
  | ExpansionCorruption() => buf_set32(bytes,15,2)
  | ScalarCorruption() => let
      val base = iadd(NORMALIZATION_HEADER_WORDS,imul(buf_get32(bytes,2),NORMALIZATION_ROW_WORDS))
    in buf_set32(bytes,base,55296) end
  | CycleCorruption() => let
      val base = iadd(NORMALIZATION_HEADER_WORDS,imul(buf_get32(bytes,2),NORMALIZATION_ROW_WORDS))
    in buf_set32(bytes,base,buf_get32(bytes,NORMALIZATION_HEADER_WORDS)) end

fun rejected(bytes: Buf): int = case+ normalization_parse(bytes) of
  | ~NormalizationRejected(error) => 0
  | ~NormalizationLoaded(data) => let val () = normalization_dispose(data) in 1 end

fun check_corruption(path: string, kind: Corruption): int = case+ text_file_read(path) of
  | ~TextFileError(code) => 1
  | ~TextFile(bytes) => let val () = corrupt(bytes,kind) in rejected(bytes) end

fun truncated {n:nat} .<n>. (n: int(n), bytes: !Buf, header: NormalizationHeader, size: int, errors: int): int =
  if n = 0 then errors else let
    val () = buf_set_len(bytes,size)
    val accepted = normalization_header_valid(bytes,header)
  in truncated(n-1,bytes,header,iadd(size,1),iadd(errors,if accepted then 1 else 0)) end

fun all_truncations(path: string): int = case+ text_file_read(path) of
  | ~TextFileError(code) => 1
  | ~TextFile(bytes) => let
      val size = buf_len(bytes)
      val header = normalization_header_read(bytes)
      val errors = truncated(airlock_nat(size),bytes,header,0,0)
      val () = buf_free(bytes)
    in errors end

fun hangul_override(): int = let
  val bytes = buf_make(68)
  val () = buf_set_len(bytes,68)
  val () = buf_set32(bytes,0,NORMALIZATION_MAGIC)
  val () = buf_set32(bytes,1,NORMALIZATION_VERSION)
  val () = buf_set32(bytes,2,1)
  val () = buf_set32(bytes,5,3)
  val () = buf_set32(bytes,6,1)
  val row = @{cp=44032,ccc=230,kind=NoMapping(),offset=0,count=0,depth=0,canonical=1,compatibility=1,excluded=false}
  val () = normalization_row_write(bytes,NORMALIZATION_HEADER_WORDS,row)
in rejected(bytes) end

implement normalization_blob_contracts(path) =
  all_truncations(path) + check_corruption(path,VersionCorruption()) + check_corruption(path,SizeCorruption())
  + check_corruption(path,KindCorruption()) + check_corruption(path,FlagCorruption())
  + check_corruption(path,RangeCorruption()) + check_corruption(path,ScalarCorruption())
  + check_corruption(path,CycleCorruption()) + check_corruption(path,ExpansionCorruption()) + hangul_override()
