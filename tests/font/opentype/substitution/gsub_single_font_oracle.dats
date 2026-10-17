#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "os/fs.sats"
staload "data_font/opentype/substitution/gsub_single.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/resources/font_fixture.sats"
staload "font/opentype/substitution/gsub_single_contracts.sats"

(* Independent raw-font reference: first/middle/last coverage entries in all
   direct SingleSubst lookups of the two documented, SHA-256-pinned test fonts. *)
implement single_font_oracle(font) = case+ font of
  | SingleLatin() => ot_fixture_words("0010 0000 010C 0D1F 0002 0370 0BE1 0003 0458 0C3D 0003 0473 0C91 0003 0D2A 0C21 0004 045C 0C47 0004 0476 0C9F 0004 04A7 0C2B 0005 045C 0C46 0005 0476 0C9E 0005 04A7 0C2A 0009 004C 00F3 0009 004D 01E6 000A 0063 0D2E 000A 0081 0D2F 000A 0BB5 0D30")
  | SingleArabic() => ot_fixture_words("003C 0000 0048 0049 0000 00A3 00A1 0000 015C 0151 0002 0009 000A 0002 000D 000A 0002 0046 0047 0003 0009 000B 0003 000D 000B 0003 0044 0045 0004 0152 0141 0004 0157 0148 0004 015C 0151 0006 0076 01E7 0006 0084 01F5 0006 00A1 0200 0007 0076 0201 0007 0084 020F 0007 00A1 0219 0008 0076 021A 0008 0084 0228 0008 00A1 0232 0009 00BF 00C0 0009 00CD 00CE 0009 00D8 00D9 000A 00BF 00C1 000A 00CD 00CF 000A 00D8 00DA 000B 00C5 00C8 000B 00C9 00CC 0011 00AA 00AB 0011 00B4 00B5 0011 00DF 00E2 0012 0048 0049 0012 00B0 00B2 0012 010A 010B 0013 008C 00A0 0013 008E 0086 0013 008F 00A1 0014 0072 0074 0014 0073 0075 0015 008C 0084 0015 008E 0086 0015 008F 00A1 0016 00E8 00E9 001A 005A 005B 001A 005C 005D 001B 005A 005B 001E 0050 0058 0020 0010 0012 0020 0013 0015 0022 0125 0126 0022 012A 012B 0024 016E 0170 0024 0171 0172 0029 0080 0090 0029 0089 0099 0029 00A1 00A3 002A 0090 0080 002A 0099 0089 002A 00A3 00A1")
