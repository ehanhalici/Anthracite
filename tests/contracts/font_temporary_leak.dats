#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_font/text/font_text_types.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"
staload "data_font/opentype/features/ot_feature_params.sats"

(* Each isolated entry must fail: the caller cannot silently drop its box. *)
#if defined(CHECK_TEXT_RESULT)
fun dropped(result: FontTextResult): void = ()
#elif defined(CHECK_TEXT_ENABLE)
fun dropped(result: FontTextEnable): void = ()
#elif defined(CHECK_SFNT_TABLE)
fun dropped(result: SfntOptional): void = ()
#elif defined(CHECK_SFNT_PARSED)
fun dropped(result: SfntParsed): void = ()
#elif defined(CHECK_COMPONENT)
fun dropped(result: ComponentRead): void = ()
#elif defined(CHECK_FEATURE_PARAMS)
fun dropped(result: OtFeatureParams): void = ()
#endif

implement main0() = ()
