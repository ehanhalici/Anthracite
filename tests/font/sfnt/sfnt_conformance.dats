#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/sfnt/sfnt.sats"
staload "font/resources/font_fixture.sats"

fun rejects(b: !Buf): int = case+ sfnt_parse(b) of
  | ~InvalidSfnt(error) => 0 | ~ValidSfnt(info) => 1

fun mapping(b: !Buf, supplementary: int): int = case+ sfnt_parse(b) of
  | ~InvalidSfnt(error) => 1
  | ~ValidSfnt(info) => let
      val m = sfnt_metrics(b,info,1)
      val tail = sfnt_metrics(b,info,2)
      val ok = ieq(sfnt_map(b,info,65),1) andalso ieq(sfnt_map(b,info,128512),supplementary)
        andalso ieq(sfnt_map(b,info,66),0) andalso ieq(sfnt_map(b,info,UNICODE_SURROGATE_START),0)
        andalso ieq(m.advance,0) andalso ieq(m.bearing,~20)
        andalso ieq(tail.advance,0) andalso ieq(tail.bearing,30)
    in if ok then 0 else 1 end

fun valid_maps(): int = let
  val f4 = fixture_font(Fixture4())
  val f12 = fixture_font(Fixture12())
  val errors = iadd(mapping(f4,0),mapping(f12,2))
  val () = buf_free(f4)
  val () = buf_free(f12)
in errors end

fun invalid_word(map: FixtureMap, at: int, value: int): int = let
  val b = fixture_font(map)
  val () = fixture_put16(b,at,value)
  val result = rejects(b)
  val () = buf_free(b)
in result end

fun invalid_dword(map: FixtureMap, at: int, value: int): int = let
  val b = fixture_font(map)
  val () = fixture_put32(b,at,value)
  val result = rejects(b)
  val () = buf_free(b)
in result end

fun invalid_cases(): int =
  invalid_dword(Fixture4(),20,2147483644)
  + invalid_dword(Fixture4(),40,10)
  + invalid_dword(Fixture4(),24,SIGNED_INT_MAX_VALUE)
  + invalid_dword(Fixture4(),28,1668112752)
  + invalid_word(Fixture4(),206,0) + invalid_word(Fixture4(),278,4)
  + invalid_word(Fixture4(),238,2) + invalid_word(Fixture4(),298,2)
  + invalid_word(Fixture4(),142,3) + invalid_word(Fixture4(),164,65534)
  + invalid_word(Fixture4(),160,65500) + invalid_word(Fixture4(),130,0)
  + invalid_dword(Fixture12(),148,SIGNED_INT_MAX_VALUE)
  + invalid_dword(Fixture12(),168,1114112) + invalid_dword(Fixture12(),172,3)
  + invalid_dword(Fixture12(),164,65)

fun truncated {n:nat} .<n>. (n: int(n), b: !Buf, length: int, errors: int): int =
  if n = 0 then errors else let
    val () = buf_set_len(b,length)
    val failed = rejects(b)
  in truncated(n-1,b,iadd(length,1),iadd(errors,failed)) end

fun truncation_cases(): int = let
  val b = fixture_font(Fixture12())
  val result = truncated(332,b,0,0)
  val () = buf_free(b)
in result end

fun range_mapping(): int = let
  val b = fixture_font(Fixture4())
  val () = fixture_put16(b,138,34)
  val () = fixture_put16(b,160,0)
  val () = fixture_put16(b,164,4)
  val () = fixture_put16(b,168,1)
  val result = mapping(b,0)
  val () = buf_free(b)
in result end

fun missing_source(): int = case+ sfnt_open("") of
  | ~LoadedSfnt(face) => let val ()=sfnt_dispose(face) in 1 end
  | ~RejectedSfnt(error) => (case+ error.kind of
    | SfntReadError() => if ine(error.code,0) then 0 else 1 | _ => 1)

fun shift_ttc_tables {n:nat} .<n>. (
  rem: int(n), b: !Buf, rec_off: int, delta: int
): void =
  if rem = 0 then ()
  else let
    val off = sfnt_be32(b, iadd(rec_off, 8))
    val () = fixture_put32(b, iadd(rec_off, 8), iadd(off, delta))
  in shift_ttc_tables(rem - 1, b, iadd(rec_off, 16), delta) end

fun wrap_in_ttc(src: !Buf): Buf = let
  val n = buf_len(src)
  val dst = buf_make(iadd(n, 16))
  val () = buf_set_len(dst, iadd(n, 16))
  val () = fixture_put32(dst, 0, 1953784678)
  val () = fixture_put16(dst, 4, 1)
  val () = fixture_put16(dst, 6, 0)
  val () = fixture_put32(dst, 8, 1)
  val () = fixture_put32(dst, 12, 16)
  val () = buf_copy_range(dst, 16, src, 0, n)
  val nt = sfnt_be16(dst, 20)
  val () = shift_ttc_tables(airlock_nat(nt), dst, 28, 16)
in dst end

fun ttc_cases(): int = let
  val base = fixture_font(Fixture4())
  val ttc = wrap_in_ttc(base)
  val ok_good = mapping(ttc, 0)
  val () = fixture_put32(ttc, 8, 0)
  val ok_bad0 = rejects(ttc)
  val () = fixture_put32(ttc, 8, 1)
  val () = fixture_put32(ttc, 12, 8)
  val ok_bad1 = rejects(ttc)
  val () = buf_free(base)
  val () = buf_free(ttc)
in iadd(ok_good, iadd(ok_bad0, ok_bad1)) end

fun cff_build_fixture(): Buf = let
  val b = buf_make(400)
  val () = buf_set_len(b, 400)
  val () = fixture_put32(b, 0, 1330926671) (* OTTO *)
  val () = fixture_put16(b, 4, 6)
  val () = fixture_put16(b, 6, 64)
  val () = fixture_put16(b, 8, 2)
  val () = fixture_put16(b, 10, 32)
  val () = fixture_put32(b, 12, 1128678944) (* CFF  *)
  val () = fixture_put32(b, 20, 108)
  val () = fixture_put32(b, 24, 52)
  val () = fixture_put32(b, 28, 1668112752) (* cmap *)
  val () = fixture_put32(b, 36, 160)
  val () = fixture_put32(b, 40, 48)
  val () = fixture_put32(b, 44, 1751474532) (* head *)
  val () = fixture_put32(b, 52, 208)
  val () = fixture_put32(b, 56, 54)
  val () = fixture_put32(b, 60, 1751672161) (* hhea *)
  val () = fixture_put32(b, 68, 264)
  val () = fixture_put32(b, 72, 36)
  val () = fixture_put32(b, 76, 1752003704) (* hmtx *)
  val () = fixture_put32(b, 84, 300)
  val () = fixture_put32(b, 88, 8)
  val () = fixture_put32(b, 92, 1835104368) (* maxp *)
  val () = fixture_put32(b, 100, 308)
  val () = fixture_put32(b, 104, 6)
  (* Minimal CFF v1 at 108 (len 52): Name(4), TopDICT(10), Str(2), Gsubr(2), CS(34) *)
  val () = buf_set(b, 108, 1); val () = buf_set(b, 109, 0)
  val () = buf_set(b, 110, 4); val () = buf_set(b, 111, 1)
  (* Name INDEX at 112: count=1 offSize=1 off=[1,2] 'A' -> 6 bytes (112..118) *)
  val () = fixture_put16(b, 112, 1); val () = buf_set(b, 114, 1)
  val () = buf_set(b, 115, 1); val () = buf_set(b, 116, 2); val () = buf_set(b, 117, 65)
  (* Top DICT INDEX at 118: count=1 offSize=1 off=[1,4] data=28 00 28 17? wait: int 34 = 173, op 17 -> 2 bytes: [173, 17], off=[1,3], total 7 bytes (118..125)? Align cleanly: off=[1,3] -> bytes at 123,124; next=125 *)
  val () = fixture_put16(b, 118, 1); val () = buf_set(b, 120, 1)
  val () = buf_set(b, 121, 1); val () = buf_set(b, 122, 3)
  val () = buf_set(b, 123, 160); val () = buf_set(b, 124, 17) (* 160-139=21 -> CS offset=21 relative to 108 => abs 129! *)
  (* String INDEX at 125: count=0 (2 bytes: 125..127) *)
  val () = fixture_put16(b, 125, 0)
  (* Global Subr INDEX at 127: count=0 (2 bytes: 127..129) *)
  val () = fixture_put16(b, 127, 0)
  (* CharStrings INDEX at 129: count=2 offSize=1 off=[1,2,10] data: gid0=[14], gid1=[139,139,21, 149, 6, 14] (len 6? let's do 8 bytes: 239=100,139=0,21=rmoveto, 239=hlineto, 14=endchar -> [239,139,21,239,14]=5 bytes -> off=[1,2,7], total 2+1+3+6=12 bytes, fits easily in 52B!) *)
  val () = fixture_put16(b, 129, 2); val () = buf_set(b, 131, 1)
  val () = buf_set(b, 132, 1); val () = buf_set(b, 133, 2); val () = buf_set(b, 134, 7)
  val () = buf_set(b, 135, 14) (* gid0: endchar *)
  val () = buf_set(b, 136, 239); val () = buf_set(b, 137, 139); val () = buf_set(b, 138, 21)
  val () = buf_set(b, 139, 239); val () = buf_set(b, 140, 14)
  (* cmap format 4 at 160: encoding record 1 (3,1,12), subtable at 172 len 32 *)
  val () = fixture_put16(b, 162, 1); val () = fixture_put16(b, 164, 3); val () = fixture_put16(b, 166, 1)
  val () = fixture_put32(b, 168, 12)
  val () = fixture_put16(b, 172, 4); val () = fixture_put16(b, 174, 32); val () = fixture_put16(b, 178, 4)
  val () = fixture_put16(b, 186, 65); val () = fixture_put16(b, 188, 65535)
  val () = fixture_put16(b, 192, 65); val () = fixture_put16(b, 194, 65535)
  val () = fixture_put16(b, 196, 65472); val () = fixture_put16(b, 198, 1) (* 65 - 64 = 1 *)
  (* head at 208 *)
  val () = fixture_put32(b, 220, 1594834165)
  val () = fixture_put16(b, 226, 1000)
  (* hhea at 264 *)
  val () = fixture_put16(b, 268, 800); val () = fixture_put16(b, 270, 65336)
  val () = fixture_put16(b, 298, 2)
  (* hmtx at 300: 2 entries *)
  val () = fixture_put16(b, 300, 500); val () = fixture_put16(b, 304, 600)
  (* maxp v0.5 at 308: 0x00005000, ng=2 *)
  val () = fixture_put32(b, 308, 20480); val () = fixture_put16(b, 312, 2)
in b end

fun check_cff_ok(b: !Buf): int = case+ sfnt_parse(b) of
  | ~InvalidSfnt(error) => 1
  | ~ValidSfnt(info) => let
      val is_cff = (case+ info.outline of | OutlineCff() => true | OutlineTrueType() => false) : bool
      val ctx = sfnt_cff_context(b, info.cff)
      val cs_ok = case+ sfnt_cff_glyph_span(b, ctx, 1) of
        | ~NoSfntTable() => false | ~HasSfntTable(sp) => ieq(sp.length, 5)
      val gid = sfnt_map(b, info, 65)
      val m = sfnt_metrics(b, info, 1)
    in
      if is_cff andalso ctx.valid andalso cs_ok andalso ieq(gid, 1) andalso ieq(m.advance, 600) then 0 else 1
    end

fun cff_cases(): int = let
  val b = cff_build_fixture()
  val ok = check_cff_ok(b)
  val () = fixture_put32(b, 308, 65536) (* invalid maxp v1.0 for OTTO *)
  val bad_maxp = rejects(b)
  val () = fixture_put32(b, 308, 20480)
  val () = buf_set(b, 124, 0) (* missing CharStrings op -> replaced by nop 0 *)
  val bad_cff = rejects(b)
  val () = buf_free(b)
in iadd(ok, iadd(bad_maxp, bad_cff)) end

fun run(): int = let
  val good = valid_maps()
  val malformed = invalid_cases()
  val short = truncation_cases()
  val range = range_mapping()
  val ttc = ttc_cases()
  val cff = cff_cases()
  val () = println!("event=sfnt_conformance mapping_errors=",good,
    " malformed_errors=",malformed," truncation_errors=",short," range_errors=",range,
    " ttc_errors=",ttc," cff_errors=",cff)
in good + malformed + short + range + ttc + cff + missing_source() end

implement main0() = if igt(run(),0) then exit(1) else ()
