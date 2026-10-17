#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_text/arabic/joining/arabic_join.sats"
extern fun word_as_joining(map: !PropertyMap(1)): ArabicJoining
implement word_as_joining(map) = arabic_joining(map,1576)
