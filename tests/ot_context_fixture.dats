#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_context_types.sats"
staload "os/fs.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_context.sats"
staload "opentype_fixture.sats"
staload "font_fixture.sats"
staload "ot_context_contracts.sats"

implement context_fixture(which) = case+ which of
  | PlainGlyph() => ot_fixture_words("0001 0008 0001 000E 0001 0001 0005 0001 0004 0002 0002 0006 0001 0002 0000 0001")
  | PlainClass() => ot_fixture_words("0002 000C 0012 0002 0000 0028 0001 0001 0005 0002 0003 0005 0005 0001 0006 0006 0002 0009 0009 0002 0001 0004 0002 0002 0002 0001 0002 0000 0001")
  | PlainCoverage() => ot_fixture_words("0003 0002 0002 0012 0018 0001 0002 0000 0001 0001 0001 0005 0001 0001 0006")
  | ChainGlyph() => ot_fixture_words("0001 0008 0001 000E 0001 0001 0005 0001 0004 0002 0002 0001 0002 0006 0002 0007 0008 0002 0001 0002 0000 0001")
  | ChainClass() => ot_fixture_words("0002 0010 0016 0020 0036 0002 0000 0040 0001 0001 0005 0001 0001 0002 0004 0003 0002 0003 0005 0005 0001 0006 0006 0002 0009 0009 0002 0001 0007 0002 0005 0006 0001 0004 0002 0003 0004 0002 0002 0002 0005 0006 0002 0001 0002 0000 0001")
  | ChainCoverage() => ot_fixture_words("0003 0002 001E 0024 0002 002A 0030 0002 0036 003C 0002 0001 0002 0000 0001 0001 0001 0002 0001 0001 0001 0001 0001 0005 0001 0001 0006 0001 0001 0007 0001 0001 0008")
implement context_fixture_mode(which) = case+ which of
  | PlainGlyph() => ContextPlain() | PlainClass() => ContextPlain() | PlainCoverage() => ContextPlain()
  | ChainGlyph() => ContextChained() | ChainClass() => ContextChained() | ChainCoverage() => ContextChained()
implement context_fixture_classes(which) = case+ which of
  | PlainGlyph() => false | PlainClass() => true | PlainCoverage() => false
  | ChainGlyph() => false | ChainClass() => true | ChainCoverage() => false
