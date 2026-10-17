#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "data_font/opentype/position/gpos_value_cache_types.sats"
staload "data_font/opentype/position/gpos_value_cache.sats"
staload "data_font/opentype/position/gpos_pair_types.sats"
staload "data_font/opentype/position/gpos_pairs.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_pair_contracts.sats"
implement gpos_pair_fixture(which) = case+ which of
  | GlyphPairs() => ot_fixture_words("0001 000E 0004 0001 0002 0016 0024 0001 0002 0005 0006 0002 0006 FFF6 0002 0007 0000 0000 0000")
  | ClassPairs() => ot_fixture_words("0002 0028 0004 0001 0032 003C 0002 0003 FFFF 0001 FFFE 0002 FFFD 0003 FFF6 000A FFF5 000B FFF4 000C 0001 0003 0005 0006 0008 0001 0005 0002 0001 0001 0001 0006 0004 0001 0002 0000 0002")
  | ZeroPairs() => ot_fixture_words("0002 0010 0000 0000 0016 001C FFFF FFFF 0001 0001 0005 0001 0000 0000 0001 0000 0000")
  | DevicePairs() => ot_fixture_words("0001 000C 0010 0020 0001 0012 0001 0001 0005 0001 0006 0008 0010 0005 0006 0001 B000 0005 0006 0002 7800")
  | AbsentSecond() => ot_fixture_words("0001 000C 0004 0000 0001 0012 0001 0001 0005 0001 0006 FFF6")
