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

fun graph_check(bytes: Buf, header: NormalizationHeader): NormalizationLoad = let
  val data = NormalizationData(bytes,header)
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
