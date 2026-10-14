#include "data_font/ot_shape_internal.hats"
fun bit(value: uint): bool = g0uint_gt_uint(value,0u) andalso g0uint_eq_uint(value land (value-1u),0u)
implement ot_shape_masks_valid(m) = bit(m.initial) andalso bit(m.medial) andalso bit(m.final)
  andalso bit(m.isolated) andalso bit(m.mirror)
  andalso g0uint_eq_uint((m.initial lor m.medial lor m.final lor m.isolated) land m.mirror,0u)
  andalso g0uint_eq_uint(m.initial land (m.medial lor m.final lor m.isolated),0u)
  andalso g0uint_eq_uint(m.medial land (m.final lor m.isolated),0u)
  andalso g0uint_eq_uint(m.final land m.isolated,0u)
fun selection_of(tag: OtTag,m: OtShapeMasks): GlyphSelection = let
  val mask: uint=case+ tag.code of
    | 1768843636 => m.initial | 1835361385 => m.medial | 1718185569 => m.final
    | 1769172844 => m.isolated | 1920232557 => m.mirror | _ => 0u
in if g0uint_eq_uint(mask,0u) then @{kind=GlyphAll(),mask=0u}
  else @{kind=GlyphMasked(),mask=mask} end

implement ot_shape_feature_selection(tag,m) = selection_of(tag,m)
