staload "mem.sats"
staload "data_font/sfnt.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_property.sats"
datatype NativeClusterFace = ClusterPreferred | ClusterAlternative | ClusterMissing
fun native_text_range_covered(b: !Buf,info: SfntInfo,ignorable: !PropertyMap(8),
  source: !ScalarText,start: int,finish: int): bool
(* Pre-shaping cmap coverage for a validated whole EGC in the source view.
   A missing mark rejects the entire face, never just the mark. Default
   ignorables remain in shaping input but do not require a nominal glyph.
   This is a candidate selection, not a promise of successful GSUB/GPOS,
   variation-selector support, or font-aware canonical decomposition. *)
fun native_text_cluster_face(preferred: !Buf,preferredInfo: SfntInfo,alternative: !Buf,alternativeInfo: SfntInfo,
  ignorable: !PropertyMap(8),source: !ScalarText,start: int,finish: int): NativeClusterFace
