#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_errors.sats"
(* Error values are flat: repeated failed loads allocate no unowned datatype
   payloads under ATS_MEMALLOC_LIBC. The I/O detail is the original ABI status. *)
implement NormIo(code) = @{reason=NormIoReason(),detail=code}
implement NormHeader() = @{reason=NormHeaderReason(),detail=0}
implement NormRanges() = @{reason=NormRangesReason(),detail=0}
implement NormGraph() = @{reason=NormGraphReason(),detail=0}
implement NormSource() = @{reason=NormSourceReason(),detail=0}
implement NormLength() = @{reason=NormLengthReason(),detail=0}
