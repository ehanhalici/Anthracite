staload "data_text/utf8.sats"
staload "data_text/normalization_types.sats"
staload "data_text/unicode_property.sats"
staload "data_text/arabic_marks_types.sats"
(* UAX #53 AMTRA, Unicode 18: NFD, then stable per-nonstarter-sequence
   promotion of MCM(220), MCM(230), shadda. CGJ/starter boundaries are kept.
   Output is a transient render view; original document bytes are untouched.
   Face-aware immediate-prefix composition belongs to the font layer. *)
fun arabic_marks_apply(data: !NormalizationData,mcm: !PropertyMap(9),source: !ScalarText): ArabicMarkResult
fun arabic_marks_apply_range(data: !NormalizationData,mcm: !PropertyMap(9),source: !ScalarText,start: int,finish: int): ArabicMarkResult
