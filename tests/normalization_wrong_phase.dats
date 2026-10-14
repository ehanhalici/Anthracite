staload "mem.sats"
staload "data_text/utf8.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_engine.sats"
(* Canonical ordering is mandatory before composition. *)
fun wrong_phase(data: !NormalizationData, text: NormalText(0)): ScalarText =
  normalization_compose(data,text)

