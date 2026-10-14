#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_parse.sats"
staload "data_font/ot_layout_tags.sats"
staload "data_font/ot_layout_plan.sats"
staload "data_font/ot_layout_feature_set.sats"
staload "data_font/ot_layout_language.sats"
staload "opentype_fixture.sats"
staload "ot_layout_contracts.sats"

extern fun layout_bad_fixture(): int = "mac#anth_die_int"
fun copy {n:nat} .<n>. (n: int(n),s: string,b: !Buf,i: int): void =
  if n = 0 then () else let val ()=buf_set(b,i,c_str_byte(s,i))
    in copy(n-1,s,b,iadd(i,1)) end
implement layout_bytes(s) = let
  val size=c_strlen(s)
  val b=buf_make(size)
  val ()=copy(airlock_nat(size),s,b,0)
  val ()=buf_set_len(b,size)
in b end
implement layout_tag(s) = case+ ot_tag_of_string(s) of
  | ~Some_vt(tag) => tag | ~None_vt() => let val code=layout_bad_fixture() in @{code=code} end
implement layout_fixture() = ot_fixture_words(
  "0001 0000 000A 0042 007A 0002 4446 4C54 000E 6C61 746E 0018 0004 0000 0000 FFFF 0000 000A 0001 5452 4B20 0018 0000 0000 0004 0002 0001 0002 0003 0000 FFFF 0001 0001 0004 6B65 726E 001A 6C69 6761 0022 6C69 6761 002C 726C 6967 0032 0000 0002 0002 0000 0000 0003 0002 0001 0002 0000 0001 0000 0000 0001 0003 0004 000A 0014 001E 0028 0001 0000 0001 0008 0001 0001 0000 0001 0008 0001 0001 0000 0001 0008 0001 0001 0000 0001 0008 0001")
implement layout_accept(b,domain,caps) = case+ ot_layout_parse(b,ot_fixture_span(b),domain,caps) of
  | ~LayoutRejected(e) => 1
  | ~LayoutAccepted(table) => let val ()=ot_layout_dispose(table) in 0 end
implement layout_reject(b,s,domain,caps) = case+ ot_layout_parse(b,s,domain,caps) of
  | ~LayoutRejected(e) => 0
  | ~LayoutAccepted(table) => let val ()=ot_layout_dispose(table) in 1 end
